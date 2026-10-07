-- Prueba de las CARROCERÍAS DE MALLA de los coches (World/Kit/CarBodies) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-carbodies.luau
--
-- Con packs FALSOS (mismos nombres, estructura y tallas que los de los docs: los oficiales de Roblox
-- con «Body», «Chassis» y 14 scripts; el Semi-Realistic Car Pack con A-Chassis, logos y «Protector»;
-- el «mesh pack» de coches europeos con textura y ruedas sueltas; el pack de policía de California)
-- y los módulos DE VERDAD (CarModel, Rides, Props, Ambient, VehicleBuild, WheelRig), comprueba:
--   * sin carga (o si falla) no cambia nada;
--   * se borran scripts, Decals, SurfaceGuis, sonidos, asientos, ruedas, logos y atributos del pack;
--   * NINGUNA marca real en nombres, textos, Decals ni atributos (lista de marcas) y nombres inventados;
--   * la malla encaja en la caja del coche (ancho, largo, techo) y con el morro a −Z;
--   * ruedas, asientos y caja de choque en su sitio; luces y matrículas en el morro y la cola de la malla;
--   * pintura (color de Body) en las piezas pintables; las de textura no se pintan;
--   * patrulla con «POLICÍA» y sus luces sobre el techo de la malla; taxi con su cartel;
--   * elección determinista y variada; el coche del jugador solo con mallas pintables;
--   * coches hechos mientras se cargaba: se cambian al terminar; el taller (VehicleBuild) pinta la
--     malla y no vuelve a enseñar la carrocería de piezas; el tráfico tiene sus plantillas (CarsMesh).

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Color3, Enum, Instance = roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum, roblox.Instance

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

---------------------------------------------------------------------
-- Cargador: script.Parent.X y require() como en Roblox (por rutas de verdad)
---------------------------------------------------------------------
local nodeMeta = {}
local function node(path: string)
	return setmetatable({ __path = path }, nodeMeta)
end
nodeMeta.__index = function(self, key)
	local path = rawget(self, "__path")
	if key == "Parent" then
		return node((path:match("^(.*)/[^/]+$")))
	end
	return node(path .. "/" .. key)
end
local fakeGame = {
	GetService = function(_, name)
		if name == "ReplicatedStorage" then
			return { Shared = node("src/shared") }
		end
		error("servicio no disponible en la prueba: " .. tostring(name))
	end,
}
local fakeTask = {
	wait = function() end,
	spawn = function(f, ...)
		f(...)
	end,
	defer = function(f, ...)
		f(...)
	end,
}
local cache = {}
local function load(path: string): any
	if cache[path] ~= nil then
		return cache[path]
	end
	local env = setmetatable({
		script = node(path),
		require = function(target)
			return load(rawget(target, "__path"))
		end,
		game = fakeGame,
		task = fakeTask,
		warn = function() end,
		print = function() end,
		Instance = Instance,
		CFrame = CFrame,
		Vector3 = Vector3,
		Color3 = Color3,
		Enum = Enum,
		UDim2 = roblox.UDim2,
		UDim = roblox.UDim,
		Font = roblox.Font,
		OverlapParams = { new = function()
			return {}
		end },
	}, { __index = getfenv(1) })
	local file = path .. ".luau"
	local result = luau.load(fs.readFile(file), { debugName = file, environment = env })()
	cache[path] = result
	return result
end

local CarBodies = load("src/server/World/Kit/CarBodies")
local CarModel = load("src/server/World/Kit/CarModel")
local Rides = load("src/server/World/Kit/Rides")
local VehicleBuild = load("src/shared/VehicleBuild")
local WheelRig = load("src/shared/WheelRig")

---------------------------------------------------------------------
-- Packs falsos
---------------------------------------------------------------------
local function mk(class: string, props: { [string]: any }, parent: Instance?): any
	local x = Instance.new(class)
	for k, v in props do
		(x :: any)[k] = v
	end
	x.Parent = parent
	return x
end
local function mesh(name: string, size: Vector3, cf: CFrame, color: Color3, parent: Instance, extra: { [string]: any }?): any
	local p = mk("MeshPart", { Name = name, Size = size, CFrame = cf, Color = color, Material = Enum.Material.SmoothPlastic }, parent)
	for k, v in extra or {} do
		(p :: any)[k] = v
	end
	return p
end
local function junk(parent: Instance, text: string)
	-- lo que nunca debe llegar: scripts, logos, textos, sonidos y atributos raros
	mk("Script", { Name = "Protector 2.0" }, parent)
	mk("Decal", { Name = text .. " logo", Texture = "rbxassetid://135553045" }, parent)
	local gui = mk("SurfaceGui", { Name = text }, parent)
	mk("TextLabel", { Text = text }, gui)
	mk("Sound", { Name = text .. " Chime" }, parent)
	parent:SetAttribute("a", "edoc otla")
end

-- Coche oficial de Roblox (2021): Body (MeshPart, carrocería), Chassis (ruedas y asiento), Scripts…
-- forward = hacia dónde mira el morro en el pack
local function officialCar(name: string, paint: Color3, size: Vector3, forward: number, parent: Instance): Model
	local car = mk("Model", { Name = name }, parent)
	local yaw = if forward > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.new()
	local at = function(x, y, z)
		return CFrame.new(50, 10, 20) * yaw * CFrame.new(x, y, z)
	end
	local body = mk("Model", { Name = "Body" }, car)
	local W, H, L = size.X, size.Y, size.Z
	mesh("Body", Vector3.new(W, H * 0.45, L), at(0, H * 0.35, 0), paint, body)
	mesh("Doors", Vector3.new(W + 0.05, H * 0.3, L * 0.4), at(0, H * 0.4, 0), paint, body)
	mesh("Cabin", Vector3.new(W * 0.85, H * 0.35, L * 0.45), at(0, H * 0.78, L * 0.05), Color3.fromRGB(30, 40, 50), body, { Material = Enum.Material.Glass, Transparency = 0.4 })
	mesh("Hood", Vector3.new(W * 0.9, 0.3, L * 0.25), at(0, H * 0.58, -L * 0.36), paint, body)
	mesh("Grille", Vector3.new(W * 0.5, 0.6, 0.3), at(0, H * 0.3, -L / 2 + 0.1), Color3.fromRGB(20, 20, 22), body)
	mesh("Headlights", Vector3.new(W * 0.8, 0.5, 0.3), at(0, H * 0.4, -L / 2 + 0.2), Color3.fromRGB(250, 250, 240), body, { Material = Enum.Material.Neon })
	mk("Decal", { Name = "Decal", Texture = "rbxassetid://289040701" }, body:FindFirstChild("Doors"))
	local badge = mesh("Badge", Vector3.new(0.6, 0.4, 0.1), at(0, H * 0.3, -L / 2), Color3.fromRGB(200, 200, 200), body)
	mk("Decal", { Name = "Logo", Texture = "rbxassetid://1" }, badge)
	junk(body:FindFirstChild("Body"), "POLICE")
	local chassis = mk("Model", { Name = "Chassis" }, car)
	mk("VehicleSeat", { Name = "VehicleSeat", Size = Vector3.new(2, 1, 2), CFrame = at(-1.5, 2, 0) }, chassis)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			mk("Part", { Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 3.2, 3.2), CFrame = at(x * (W / 2 - 0.6), 1.6, z * L * 0.315) }, chassis)
		end
	end
	local scripts = mk("Folder", { Name = "Scripts" }, car)
	for i = 1, 14 do
		mk("Script", { Name = "Script" .. i }, scripts)
	end
	mk("Folder", { Name = "Remotes" }, car)
	return car
end

local AQUA, RED, WHITE = Color3.fromRGB(60, 190, 200), Color3.fromRGB(200, 40, 40), Color3.fromRGB(240, 240, 240)
local function officialPack(packName: string, variants: { { string | Color3 } }, size: Vector3, forward: number): Instance
	local pack = mk("Model", { Name = packName })
	for _, v in variants do
		officialCar(v[1] :: string, v[2] :: Color3, size, forward, pack)
	end
	return pack
end

-- A-Chassis (Semi-Realistic Car Pack): Body/Body/Paint, Misc con logos, Wheels/FL…, DriveSeat
local function aChassis(name: string, size: Vector3, parent: Instance)
	local car = mk("Model", { Name = name }, parent)
	local W, H, L = size.X, size.Y, size.Z
	local body = mk("Model", { Name = "Body" }, car)
	local inner = mk("Model", { Name = "Body" }, body)
	mesh("Paint", Vector3.new(W, H * 0.5, L), CFrame.new(0, H * 0.4, 0), Color3.fromRGB(90, 90, 160), inner)
	mesh("Paint", Vector3.new(W * 0.9, H * 0.3, L * 0.5), CFrame.new(0, H * 0.8, 0.5), Color3.fromRGB(90, 90, 160), inner)
	mesh("Window", Vector3.new(W * 0.8, H * 0.25, L * 0.45), CFrame.new(0, H * 0.82, 0.4), Color3.fromRGB(20, 30, 40), inner, { Transparency = 0.5 })
	local gmc = mesh("gmc_badge", Vector3.new(0.5, 0.3, 0.1), CFrame.new(0, H * 0.4, -L / 2), Color3.fromRGB(200, 0, 0), inner)
	mk("Decal", { Name = "TOYOTA" }, gmc)
	mesh("Supra Logo", Vector3.new(0.5, 0.3, 0.1), CFrame.new(0, H * 0.5, L / 2), Color3.fromRGB(200, 0, 0), inner)
	mesh("License Plate", Vector3.new(1.5, 0.5, 0.1), CFrame.new(0, H * 0.3, L / 2), WHITE, inner)
	junk(inner, "NISSAN")
	local wheels = mk("Model", { Name = "Wheels" }, car)
	for _, wn in { { "FL", -1, -1 }, { "FR", 1, -1 }, { "RL", -1, 1 }, { "RR", 1, 1 } } do
		local w = mk("Part", { Name = wn[1], Size = Vector3.new(1.2, 3, 3), CFrame = CFrame.new(wn[2] * (W / 2 - 0.6), 1.5, wn[3] * L * 0.32) }, wheels)
		local parts = mk("Model", { Name = "Parts" }, w)
		mesh("Rim", Vector3.new(1, 2, 2), w.CFrame, Color3.fromRGB(200, 200, 200), parts)
	end
	mk("VehicleSeat", { Name = "DriveSeat", CFrame = CFrame.new(-1.5, 2, 0) }, car)
	mk("Script", { Name = "A-Chassis Tune" }, car)
end

-- «mesh pack» europeo: 6 MeshPart por coche, a lo largo de X, con textura; ruedas «wheel.036_0»
local function euroCar(name: string, parent: Instance)
	local car = mk("Model", { Name = name }, parent)
	-- morro a −X: el voladizo de delante (3,6) es más largo que el de detrás (2,4)
	mesh("Object_1", Vector3.new(14, 4.2, 6.9), CFrame.new(0, 2.9, 0), WHITE, car, { TextureID = "rbxassetid://9001" })
	mesh("Object_2", Vector3.new(7, 1.6, 6.2), CFrame.new(1, 4.4, 0), Color3.fromRGB(20, 20, 20), car, { TextureID = "rbxassetid://9002", Transparency = 0.3 })
	for _, x in { -3.4, 4.6 } do
		for _, z in { -2.8, 2.8 } do
			mesh("wheel.036_0", Vector3.new(2.3, 2.3, 1), CFrame.new(x, 1.15, z), Color3.fromRGB(20, 20, 20), car)
		end
	end
	return car
end

-- Coche del importador 3D de Roblox: la carrocería es una MeshPart y lo demás cuelga DENTRO de ella
-- (cristal, interior y ruedas). Así venían casi todos los del «mesh pack» en un servidor de verdad, y
-- antes no se encontraban (salía 1 europeo de 11).
local function euroImported(name: string, parent: Instance)
	local body = mesh(name, Vector3.new(14, 4.2, 6.9), CFrame.new(0, 2.9, 0), WHITE, parent, { TextureID = "rbxassetid://9001" })
	mesh("Object_2", Vector3.new(7, 1.6, 6.2), CFrame.new(1, 4.4, 0), Color3.fromRGB(20, 20, 20), body, { TextureID = "rbxassetid://9002", Transparency = 0.3 })
	for _, x in { -3.4, 4.6 } do
		for _, z in { -2.8, 2.8 } do
			mesh("wheel.036_0", Vector3.new(2.3, 2.3, 1), CFrame.new(x, 1.15, z), Color3.fromRGB(20, 20, 20), body)
		end
	end
	return body
end

-- Lo que de verdad llega al servidor (v90, scripts/cloud): cada malla en su propio Model
-- («206_4/Object_4/Object_0») y las ruedas dos niveles abajo («wheel.036_0/Object_72/Object_2»).
-- Contando solo mallas sueltas no se encontraba ninguno (salían 21 carrocerías de 32).
local function euroWrapped(name: string, parent: Instance)
	local car = mk("Model", { Name = name }, parent)
	local function wrap(mname: string, size: Vector3, cf: CFrame, color: Color3, depth: number, props: { [string]: any }?)
		local at: Instance = car
		for i = 1, depth do
			at = mk("Model", { Name = if i == 1 then mname else "Object_" .. i }, at)
		end
		mesh("Object_0", size, cf, color, at, props)
	end
	wrap("Object_4", Vector3.new(14, 4.2, 6.9), CFrame.new(0, 2.9, 0), WHITE, 1, { TextureID = "rbxassetid://9001" })
	wrap("Object_5", Vector3.new(7, 1.6, 6.2), CFrame.new(1, 4.4, 0), Color3.fromRGB(20, 20, 20), 1, { TextureID = "rbxassetid://9002", Transparency = 0.3 })
	for i, x in { -3.4, 4.6 } do
		for j, z in { -2.8, 2.8 } do
			wrap(("wheel.03%d_%d"):format(i * 2 + j, i * 2 + j), Vector3.new(2.3, 2.3, 1), CFrame.new(x, 1.15, z), Color3.fromRGB(20, 20, 20), 2)
		end
	end
	return car
end

-- A-Chassis metido en otra carpeta: el coche de dentro se llama «Chassis» y el nombre de verdad
-- está fuera (así se perdía el Camry)
-- (en el servidor, v91: delante del «Chassis» viene «Drivetrain», solo ejes y diferencial de cristal,
-- que también parece un coche; se cogía ese y salía «tapa el 0%»)
local function aChassisNested(name: string, size: Vector3, parent: Instance)
	local outer = mk("Model", { Name = name }, parent)
	local drive = mk("Model", { Name = "Drivetrain" }, outer)
	for i, x in { -1.5, 1.5, -1.5, 1.5 } do
		mesh(if i <= 2 then "Axle" else "Shaft", Vector3.new(0.6, 0.5, 0.5), CFrame.new(x, 1, if i <= 2 then -6 else 6), WHITE, drive, { Material = Enum.Material.Glass })
	end
	aChassis("Chassis", size, outer)
	return outer
end

-- Pick-up cuyos paneles están en «Misc» y no en «Body» (en Body solo molduras y luces): con solo
-- Body saldría una camioneta invisible
local function pickupMisc(name: string, size: Vector3, parent: Instance)
	local car = mk("Model", { Name = name }, parent)
	local W, H, L = size.X, size.Y, size.Z
	local body = mk("Model", { Name = "Body" }, car)
	mesh("Trim", Vector3.new(W, 0.3, 0.4), CFrame.new(0, H * 0.3, -L / 2), Color3.fromRGB(200, 200, 205), body)
	mesh("Lamp", Vector3.new(W * 0.8, 0.4, 0.3), CFrame.new(0, H * 0.45, -L / 2), Color3.fromRGB(250, 250, 240), body, { Material = Enum.Material.Neon })
	mesh("Window", Vector3.new(W * 0.8, H * 0.25, L * 0.3), CFrame.new(0, H * 0.82, -L * 0.1), Color3.fromRGB(20, 30, 40), body, { Transparency = 0.5 })
	local misc = mk("Model", { Name = "Misc" }, car)
	mesh("Paint", Vector3.new(W, H * 0.5, L), CFrame.new(0, H * 0.4, 0), Color3.fromRGB(150, 30, 30), misc)
	mesh("Paint", Vector3.new(W * 0.9, H * 0.35, L * 0.35), CFrame.new(0, H * 0.8, -L * 0.1), Color3.fromRGB(150, 30, 30), misc)
	local wheels = mk("Model", { Name = "Wheels" }, car)
	for _, wn in { { "FL", -1, -1 }, { "FR", 1, -1 }, { "RL", -1, 1 }, { "RR", 1, 1 } } do
		local w = mk("Part", { Name = wn[1], Size = Vector3.new(1.2, 3, 3), CFrame = CFrame.new(wn[2] * (W / 2 - 0.6), 1.5, wn[3] * L * 0.32) }, wheels)
		local parts = mk("Model", { Name = "Parts" }, w)
		mesh("Rim", Vector3.new(1, 2, 2), w.CFrame, Color3.fromRGB(200, 200, 200), parts)
	end
	mk("VehicleSeat", { Name = "DriveSeat", CFrame = CFrame.new(-1.5, 2, -2) }, car)
	return car
end

local function packs(): { [number]: Instance }
	local out = {}
	out[6418239833] = officialPack("Sedan", { { "Sedan (aqua)", AQUA }, { "Sedan (red)", RED } }, Vector3.new(8.6, 6.2, 20.6), 1)
	out[6418234850] = officialPack("SUV", { { "SUV (blue)", Color3.fromRGB(40, 80, 200) }, { "SUV (black)", Color3.fromRGB(240, 200, 30) } }, Vector3.new(9.8, 8.1, 20.9), -1)
	out[6418225759] = officialPack("Pickup Truck", { { "Pickup (white)", WHITE }, { "Pickup (red)", RED } }, Vector3.new(10.6, 9.6, 26.6), -1)
	out[6433316269] = officialPack("Van", { { "Van (pro)", Color3.fromRGB(240, 180, 40) } }, Vector3.new(11.6, 9.7, 26.2), -1)
	out[6418230807] = officialPack("Police Car", { { "Police Car", WHITE } }, Vector3.new(9.4, 6.5, 21.1), 1)
	local semi = mk("Model", { Name = "Semi-Realistic Car Pack" })
	local folder = mk("Folder", { Name = "Cars" }, semi)
	aChassisNested("2008 Toyota Camry LE", Vector3.new(8.6, 6.4, 21.3), folder)
	aChassis("1989 GMC Suburban", Vector3.new(8.8, 8.2, 22), folder)
	pickupMisc("1998 Chevrolet Silverado C1500", Vector3.new(9.2, 8, 23), folder)
	-- Deportivos (para los coches del pase) y el de «Protector» que no se usa
	aChassis("1998 Toyota Supra RZ Turbo", Vector3.new(8.1, 5.5, 18.6), folder)
	aChassis("1995 Nissan Silvia S14 Zenki", Vector3.new(8.8, 5.6, 19.6), folder)
	aChassis("2015 Dodge Challenger SRT Hellcat Redeye", Vector3.new(8.6, 5.3, 17.9), folder)
	aChassis("2012 Dodge Challenger SRT-8", Vector3.new(8.7, 5.5, 20.6), folder)
	aChassis("1969 Dodge Charger R/T", Vector3.new(8.8, 5.5, 20.8), folder)
	aChassis("1969 Pontiac Firebird Formula 400", Vector3.new(8.8, 5.7, 20.5), folder)
	aChassis("1991 Toyota Supra MK3 Turbo", Vector3.new(8.7, 5.4, 19.0), folder)
	aChassis("1986 Toyota Corolla AE86 Sprinter Trueno", Vector3.new(8.5, 5.8, 17.8), folder)
	aChassis("1958 Plymouth Fury", Vector3.new(9.4, 6.9, 22.3), folder)
	aChassis("1999 Nissan Skyline R34 GT-R", Vector3.new(8.5, 5.4, 20.6), folder)
	out[9432856072] = semi
	-- (como en el servidor: 8 coches del importador sueltos y 3 modelos; uno sin nombre útil)
	local euro = mk("Model", { Name = "mesh pack" })
	for _, n in { "206_4", "Hiace_9", "Astra_19", "Almera_39", "Avensis_14", "AClass_34" } do
		euroWrapped(n, euro)
	end
	for _, n in { "Vectra_49", "Golf_24" } do
		euroImported(n, euro)
	end
	euroCar("Volkswagen Sharan 1995", euro)
	euroCar("Object_77", euro)
	-- (el Primera del servidor: todo se llama «Primera…», y «p-rim-era» lo tiraba todo)
	local primera = mk("Model", { Name = "nissan primera" }, euro)
	local at: Instance = primera
	for _, n in { "Sketchfab_model", "nissan primera.fbx", "RootNode", "nissan_primera", "Primerabody_4" } do
		at = mk("Model", { Name = n }, at)
	end
	local function node(n: string, size: Vector3, cf: CFrame, color: Color3, extra: { [string]: any }?)
		mesh("Primerabody_4_" .. n .. "_0", size, cf, color, mk("Model", { Name = "Primerabody_4_" .. n .. "_0_Node" }, at), extra)
	end
	node("PrimeraBody", Vector3.new(14, 4.2, 6.4), CFrame.new(0, 2.9, 0), WHITE, { TextureID = "rbxassetid://9001" })
	node("PrimeraArches", Vector3.new(13.6, 2, 6.4), CFrame.new(0, 1.6, 0), WHITE)
	node("PrimeraGlass", Vector3.new(7, 1.6, 5.6), CFrame.new(1, 4.4, 0), Color3.fromRGB(20, 20, 20), { Transparency = 0.3 })
	node("PrimeraTyre", Vector3.new(10.3, 2.2, 6.4), CFrame.new(0.6, 1.1, 0), Color3.fromRGB(20, 20, 20))
	out[97902046131324] = euro
	local chp = mk("Model", { Name = "CHP pack" })
	aChassis("CHP Charger", Vector3.new(9, 8.3, 19.9), chp)
	aChassis("Crown Victoria V2", Vector3.new(8.9, 7, 21.3), chp)
	out[4573650411] = chp
	-- Reemplazos limpios (docs/assets-reemplazos.md): autobús urbano (5 mallas, una «Decals» con el
	-- rótulo «CENTURY LINE 7701»), autocar (ruedas de malla y suciedad), camión caja y rueda
	local bus = mk("Model", { Name = "City Bus" })
	mesh("Body", Vector3.new(14, 12, 55), CFrame.new(0, 7, 0), WHITE, bus, { TextureID = "rbxassetid://7001" })
	mesh("Glass", Vector3.new(13.6, 4, 50), CFrame.new(0, 9, 0), Color3.fromRGB(20, 30, 40), bus, { Transparency = 0.4 })
	mesh("Glass2", Vector3.new(12, 5, 0.5), CFrame.new(0, 9, -27.4), Color3.fromRGB(20, 30, 40), bus, { Transparency = 0.4 })
	mesh("Lights", Vector3.new(12, 1, 55.2), CFrame.new(0, 3, 0), Color3.fromRGB(250, 250, 240), bus)
	local decals = mesh("Decals", Vector3.new(10, 1.5, 55.3), CFrame.new(0, 12, 0), Color3.fromRGB(250, 160, 30), bus)
	local g = mk("SurfaceGui", {}, decals)
	mk("TextLabel", { Text = "CENTURY LINE 7701" }, g)
	out[16358361587] = bus
	local coach = mk("Model", { Name = "Tour Bus Abandonned" })
	mesh("Paint", Vector3.new(11, 10, 46), CFrame.new(0, 7, 0), Color3.fromRGB(200, 200, 205), coach, { TextureID = "rbxassetid://7002" })
	mesh("Glass", Vector3.new(10.6, 3, 44), CFrame.new(0, 9.5, 0), Color3.fromRGB(20, 30, 40), coach, { Transparency = 0.3 })
	mesh("Chrome", Vector3.new(11.2, 0.5, 46.2), CFrame.new(0, 3, 0), Color3.fromRGB(220, 220, 225), coach)
	mk("Decal", { Name = "Dirt", Texture = "rbxassetid://5" }, coach:FindFirstChild("Paint"))
	mk("Texture", { Name = "Rust", Texture = "rbxassetid://6" }, coach:FindFirstChild("Paint"))
	mk("BoolValue", { Name = "Abandoned" }, coach)
	-- morro a −Z: voladizo de delante 6, de detrás 9 (motor detrás)
	for _, z in { -17, 14 } do
		for _, x in { -4.6, 4.6 } do
			mesh("Wheels", Vector3.new(1.4, 3.6, 3.6), CFrame.new(x, 1.8, z), Color3.fromRGB(25, 25, 25), coach)
		end
	end
	out[95641562400547] = coach
	local truck = mk("Model", { Name = "box truck mesh" })
	-- a lo largo de X, cabina en +X
	mesh("Box", Vector3.new(19, 11, 9), CFrame.new(-4, 6.5, 0), WHITE, truck, { TextureID = "rbxassetid://7003" })
	mesh("Cab", Vector3.new(8, 9, 8.6), CFrame.new(10, 5, 0), WHITE, truck, { TextureID = "rbxassetid://7004" })
	mesh("Glass", Vector3.new(0.4, 3, 7.6), CFrame.new(13.8, 7, 0), Color3.fromRGB(20, 30, 40), truck, { Transparency = 0.4 })
	out[4128265113] = truck
	local wheel = mk("Model", { Name = "Realistic Car Wheel" })
	mesh("Tire", Vector3.new(1.5, 2.7, 2.7), CFrame.new(0, 0, 0), Color3.fromRGB(25, 25, 25), wheel)
	mesh("Rim", Vector3.new(1.2, 2, 2), CFrame.new(0.1, 0, 0), Color3.fromRGB(200, 200, 205), wheel)
	mesh("Bolts", Vector3.new(0.2, 0.8, 0.8), CFrame.new(0.6, 0, 0), Color3.fromRGB(150, 150, 150), wheel)
	out[17601139281] = wheel
	return out
end

---------------------------------------------------------------------
-- Ayudas
---------------------------------------------------------------------
local CF = CFrame.new(120, 0.4, -60) * CFrame.Angles(0, 0.7, 0)
local function parts(model: Instance, all: boolean?): { any }
	local out = {}
	for _, d in model:GetDescendants() do
		-- (la carpeta «Tire» de la plantilla: el neumático, centrado en su rueda; no cuenta)
		if d:IsA("BasePart") and (all or not (d.Parent and d.Parent.Name == "Tire")) then
			table.insert(out, d)
		end
	end
	return out
end
local function localOf(part: any, base: any): any
	return base:PointToObjectSpace(part.CFrame.Position)
end
local function snapshot(model: Instance): string
	local list = {}
	for _, p in parts(model) do
		local pos = p.CFrame.Position
		table.insert(list, ("%s|%.2f,%.2f,%.2f|%.2f|%s"):format(p.Name, pos.X, pos.Y, pos.Z, p.Transparency, tostring(p.Color)))
	end
	table.sort(list)
	return table.concat(list, ";")
end
local function meshBounds(model: Instance, base: any): (any, any)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, p in parts(model) do
		if p:GetAttribute("CarMesh") then
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local c = base:PointToObjectSpace((p.CFrame * CFrame.new(p.Size.X / 2 * sx, p.Size.Y / 2 * sy, p.Size.Z / 2 * sz)).Position)
						lo = Vector3.new(math.min(lo.X, c.X), math.min(lo.Y, c.Y), math.min(lo.Z, c.Z))
						hi = Vector3.new(math.max(hi.X, c.X), math.max(hi.Y, c.Y), math.max(hi.Z, c.Z))
					end
				end
			end
		end
	end
	return lo, hi
end
local BLOCKLIST = {
	"hyundai", "toyota", "ford", "chevrolet", "bmw", "mercedes", "audi", "honda", "nissan", "tesla", "thaco",
	"chp", "ferrari", "lamborghini", "porsche", "volkswagen", "kia", "dodge", "jeep", "gmc", "peugeot", "opel",
	"plymouth", "pontiac", "supra", "camry", "corolla", "silverado", "suburban", "elantra", "hiace", "golf",
	"astra", "crown victoria", "police", "nova",
}
-- Textos que se ven o se guardan en un modelo: nombres, textos, Decals y atributos de texto
local function brandHits(root: Instance): { string }
	local hits = {}
	local function scan(text: string, where: string, isName: boolean?)
		local t = string.lower(text)
		for _, b in BLOCKLIST do
			-- (nuestras piezas PoliceStripe / PoliceCheck se llaman así por dentro; no se ven)
			if isName and b == "police" and (t == "policestripe" or t == "policecheck" or t == "policecar") then
				continue
			end
			-- (POLICÍA sí; POLICE no)
			if string.find(t, b, 1, true) and not (b == "police" and string.find(t, "policía", 1, true)) then
				table.insert(hits, where .. ": " .. text)
			end
		end
	end
	for _, d in { root, table.unpack(root:GetDescendants()) } do
		scan(d.Name, d:GetFullName(), true)
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			scan(d.Text, "Text de " .. d:GetFullName())
		end
		if d:IsA("Decal") or d:IsA("Texture") then
			scan(d.Texture, "Decal " .. d:GetFullName())
		end
		for name, value in d:GetAttributes() do
			if type(value) == "string" then
				scan(value, "atributo " .. name .. " de " .. d:GetFullName())
			end
		end
	end
	return hits
end

---------------------------------------------------------------------
print("▶ Sin carga: nada cambia")
CarBodies.reset()
local plain = CarModel.build(nil, CF, RED, { Name = "ParkedCar", Variant = "Berlina", Lite = true })
local before = snapshot(plain)
check(CarBodies.dress(plain, CF, { Role = "Parked", Key = "x" }) == false, "dress sin plantillas devuelve false")
check(snapshot(plain) == before, "el coche de piezas no cambia")
CarBodies.reset()
CarBodies.start(function()
	return nil
end)
check(CarBodies.State == "failed", "si no carga ningún pack: estado «failed»")
local plain2 = CarModel.build(nil, CF, RED, { Name = "ParkedCar", Variant = "Berlina", Lite = true })
local before2 = snapshot(plain2)
check(CarBodies.dress(plain2, CF, { Role = "Parked" }) == false and snapshot(plain2) == before2, "carga fallida: el coche se queda como estaba")
local ride = Rides.build("Coche", nil, CF, RED)
check(ride:GetAttribute("CarBody") == nil and ride:FindFirstChild("Body").Transparency == 0, "Rides.build sin mallas: coche de siempre")

---------------------------------------------------------------------
print("▶ Coches hechos mientras se carga y carga con packs falsos")
CarBodies.reset()
local world = Instance.new("Folder")
world.Name = "Mundo"
local early = CarModel.build(world, CF, AQUA, { Name = "ParkedCar", Variant = "Compacto", Lite = true })
CarBodies.dress(early, CF, { Role = "Parked", Key = "temprano" })
check(early:GetAttribute("CarBody") == nil, "antes de cargar: sin malla (apuntado)")
local fake = packs()
local asked = {}
CarBodies.start(function(id)
	table.insert(asked, id)
	return fake[id]
end)
check(CarBodies.State == "ready", "estado «ready»")
local lib = CarBodies.library()
local names = {}
for _, t in lib do
	names[t.Name] = t
end
check(#lib >= 15, ("plantillas: %d (oficiales, Semi-Realistic, europeos y patrulla)"):format(#lib))
check(names["Aurea Berlina"] and names["Kestrel Sierra"] and names["Toro Faena"] and names["Brisa Carga"] and names["Valmar Patrulla"], "las 5 oficiales (sedán, SUV, pick-up, furgoneta, policía)")
check(names["Aurea Serena"] and names["Kestrel Ranchera"] and names["Toro Campo"] and names["Brisa Sprint"] and names["Valmar Clásico"], "las 5 del Semi-Realistic Car Pack")
local euroAll = true
for _, n in { "Brisa Uno", "Toro Reparto", "Aurea Nube", "Kestrel Alba", "Aurea Paseo", "Valmar Mini", "Kestrel Vela", "Brisa Ola", "Toro Familia", "Toro Familia Plus", "Kestrel Lince" } do
	if not names[n] then
		euroAll = false
		print("    falta " .. n)
	end
end
check(euroAll, "los 11 europeos del «mesh pack» (también los del importador: malla dentro de malla, y nombres con marca)")
check(names["Aurea Serena"] ~= nil, "el Camry metido en otra carpeta («…Camry LE/Chassis») se encuentra por el nombre de fuera")
check(names["Toro Campo"] and names["Toro Campo"]:GetAttribute("Cover") >= CarBodies.MinCover, ("pick-up con los paneles fuera de «Body»: se mira el coche entero (tapa el %s)"):format(tostring(names["Toro Campo"] and names["Toro Campo"]:GetAttribute("Cover"))))
local sports = 0
for _, t in lib do
	local roles = t:GetAttribute("Roles")
	if roles == "Sport" then
		sports += 1
	end
end
check(sports == 6, ("6 deportivos para el pase (y no el de «Protector»): %d"):format(sports))
do
	local ghost = mk("Model", { Name = "Ghost Van" })
	local gb = mk("Model", { Name = "Body" }, ghost)
	mesh("Window", Vector3.new(7, 2, 8), CFrame.new(0, 5, 0), Color3.fromRGB(20, 30, 40), gb, { Transparency = 0.5 })
	mesh("Lamp", Vector3.new(6, 0.4, 0.3), CFrame.new(0, 3, -9), WHITE, gb, { Material = Enum.Material.Neon })
	mesh("Trim", Vector3.new(7, 0.3, 0.3), CFrame.new(0, 2, 9), WHITE, gb)
	local gm, why = CarBodies.template(ghost, { Name = "Fantasma", Brand = "TORO", Type = "Furgoneta" }, 1)
	check(gm == nil and type(why) == "string" and string.find(why, "invisible", 1, true) ~= nil, "una carrocería con solo cristales y luces no se usa (saldría una furgoneta invisible): " .. tostring(why))
end
check(names["Valmar Patrulla Clásica"] ~= nil, "la patrulla clásica (un solo coche del pack de policía)")
local skylineUsed = false
for _, t in lib do
	if string.find(string.lower(t.Name), "skyline") then
		skylineUsed = true
	end
end
check(not skylineUsed, "el coche con «Protector» que no está en la lista no se usa")
check(table.find(asked, 15418880736) ~= nil and table.find(asked, 18912826861) == nil and table.find(asked, 130974691456028) == nil and table.find(asked, 16893586720) == nil and table.find(asked, 18577576400) == nil and table.find(asked, 131247677717086) == nil, "se pide la berlina pesada; ni el autobús, autocar, camión, ruedas ni coches descartados")
check(table.find(asked, 16358361587) and table.find(asked, 95641562400547) and table.find(asked, 4128265113) and table.find(asked, 17601139281) and table.find(asked, 8448337398) == nil, "los reemplazos limpios: autobús, autocar, camión y rueda (la de respaldo no hace falta)")
check(names["Valmar Urbano"] and names["Toro Ruta"] and names["Kestrel Reparto"], "plantillas del autobús, el autocar y el camión")
check(CarBodies.wheel() ~= nil and #CarBodies.wheel():GetChildren() == 3, "rueda de malla (neumático + llanta)")
check(early:GetAttribute("CarBody") ~= nil, "el coche apuntado mientras cargaba ya tiene malla")

---------------------------------------------------------------------
print("▶ Plantillas limpias y sin marcas")
local dirty, badNames, attrs = {}, {}, {}
local ALLOWED = { CarShell = true, CarGlass = true, CarTrim = true, CarBadge = true, TireMesh = true }
local keptDecals = 0
for _, t in lib do
	for _, d in t:GetDescendants() do
		if (d:IsA("Decal") or d:IsA("Texture")) and d.Name == "CarDecal" and not CarBodies.isLogo(d) then
			keptDecals += 1
		elseif d:IsA("LuaSourceContainer") or d:IsA("Decal") or d:IsA("Texture") or d:IsA("Sound") or d:IsA("Seat") or d:IsA("VehicleSeat") then
			table.insert(dirty, t.Name .. "/" .. d.Name)
		elseif (d:IsA("SurfaceGui") or d:IsA("TextLabel")) and not (d.Parent and (d.Parent.Name == "CarBadge" or (d.Parent.Parent and d.Parent.Parent.Name == "CarBadge"))) then
			table.insert(dirty, t.Name .. "/" .. d.ClassName)
		end
		if d:IsA("BasePart") then
			if not ALLOWED[d.Name] then
				table.insert(badNames, t.Name .. "/" .. d.Name)
			end
			if d:GetAttribute("a") ~= nil then
				table.insert(attrs, t.Name)
			end
			if d.CanCollide or d.CanTouch or d.CanQuery then
				table.insert(dirty, t.Name .. "/" .. d.Name .. " choca" .. tostring(d.CanCollide) .. tostring(d.CanTouch) .. tostring(d.CanQuery))
			end
		end
	end
end
check(#dirty == 0, "sin scripts, Decals, textos, sonidos, asientos ni colisión " .. table.concat(dirty, ", "):sub(1, 200))
check(#badNames == 0, "piezas renombradas (CarShell/CarGlass/CarTrim/CarBadge) " .. table.concat(badNames, ", "):sub(1, 200))
check(#attrs == 0, "sin los atributos raros del pack")
check(keptDecals > 0, "los Decals que no son logos (detalles) se quedan")
local textures = 0
for _, p in parts(names["Brisa Uno"]) do
	if p:IsA("MeshPart") and select(2, pcall(function() return p.TextureID end)) ~= "" then
		textures += 1
	end
end
check(textures >= 2, "las texturas (TextureID) de las mallas se quedan")
local wheelsIn = 0
for _, t in lib do
	for _, p in parts(t) do
		if string.find(string.lower(p.Name), "wheel") or p.Name == "FL" then
			wheelsIn += 1
		end
	end
end
check(wheelsIn == 0, "las ruedas de la malla no se copian (se quedan las nuestras)")
local hits = {}
for _, t in lib do
	for _, h in brandHits(t) do
		table.insert(hits, h)
	end
	local brand = t:GetAttribute("Brand")
	check(table.find(CarBodies.Brands, brand) ~= nil and #t:GetChildren() > 0, t.Name .. ": marca inventada " .. tostring(brand))
end
check(#hits == 0, "plantillas sin marcas reales " .. table.concat(hits, " | "):sub(1, 300))
for _, src in CarBodies.Sources do
	for _, pick in src.Picks do
		check(not CarBodies.isBrand(pick.Name) and not CarBodies.isBrand(pick.Brand), "nombre inventado: " .. pick.Name .. " (" .. pick.Brand .. ")")
	end
end
local badges = 0
for _, p in parts(names["Aurea Berlina"]) do
	if p.Name == "CarBadge" then
		badges += 1
	end
end
check(badges == 2, "placas con la marca inventada delante y detrás (tapan el logo)")

---------------------------------------------------------------------
print("▶ Encaje en la caja del coche")
for _, t in lib do
	if t:GetAttribute("Heavy") then
		continue
	end
	local lo, hi = CarBodies.bounds(parts(t) :: any)
	local typ = CarBodies.Types[t:GetAttribute("Type")]
	local W, L = hi.X - lo.X, hi.Z - lo.Z
	check(W > 5 and W < 7.8 and L > 11 and L < 17 and math.abs(lo.X + hi.X) < 0.3, ("%s: %.1f × %.1f, centrada"):format(t.Name, W, L))
	check(hi.Y > typ.Roof - 0.8 and hi.Y < typ.Roof + 1.2 and lo.Y > -0.2 and lo.Y < 1.5, ("%s: de %.1f a %.1f de alto (techo %s %.1f)"):format(t.Name, lo.Y, hi.Y, t:GetAttribute("Type"), typ.Roof))
end
-- Morro a −Z: el capó (más bajo, delante) y los faros del pack quedan delante
for _, name in { "Aurea Berlina", "Kestrel Sierra", "Valmar Patrulla" } do
	local t = names[name]
	local neon
	for _, p in parts(t) do
		if p.Material == Enum.Material.Neon then
			neon = p
		end
	end
	check(neon and neon.CFrame.Position.Z < -4, name .. ": los faros de la malla quedan en el morro (−Z) — forward: " .. tostring(t:GetAttribute("Forward")))
end
check(names["Brisa Uno"]:GetAttribute("Forward") == "voladizo", "europeo sin asiento: el morro por el voladizo")

-- Morro por el perfil (los que no traen asiento: en el juego se mide la malla con rayos y, si el
-- voladizo se equivocó, la plantilla se hace otra vez girada; antes algunos iban marcha atrás)
do
	-- Perfiles de 30 tramos, del extremo −Z al +Z (alto del techo = 5)
	local function profile(spec: { { number } }): { number }
		local out = {}
		for _, seg in spec do
			for _ = 1, seg[1] do
				table.insert(out, seg[2])
			end
		end
		return out
	end
	local function reversed(t: { number }): { number }
		local out = {}
		for i = #t, 1, -1 do
			table.insert(out, t[i])
		end
		return out
	end
	local sedan = profile({ { 1, 2 }, { 8, 3.2 }, { 3, 4.2 }, { 10, 5 }, { 3, 4.2 }, { 5, 3.5 } }) -- capó largo, maletero corto
	local hatch = profile({ { 1, 2 }, { 8, 3.1 }, { 3, 4.3 }, { 15, 5 }, { 3, 4.4 } }) -- el portón sube hasta el final
	local coupe = profile({ { 1, 2 }, { 10, 3 }, { 3, 4 }, { 8, 5 }, { 4, 3.8 }, { 2, 3.4 }, { 2, 4.1 } }) -- deportivo con alerón
	local mpv = profile({ { 4, 3.2 }, { 2, 4.2 }, { 24, 5 } }) -- monovolumen: capó corto
	local van = profile({ { 1, 4.2 }, { 28, 5 }, { 1, 4.4 } }) -- furgoneta de morro chato: no se sabe
	for _, case in { { "berlina", sedan }, { "compacto", hatch }, { "deportivo con alerón", coupe }, { "monovolumen", mpv } } do
		local name, t = case[1] :: string, case[2] :: { number }
		check(CarBodies.noseFromProfile(t) == -1 and CarBodies.noseFromProfile(reversed(t)) == 1,
			("perfil de %s: el morro es la punta del capó (y girado, se ve al revés)"):format(name))
	end
	check(CarBodies.noseFromProfile(van) == 0 and CarBodies.noseFromProfile({}) == 0, "furgoneta de morro chato (o sin medir): no se toca lo que dijo el voladizo")
	local src = fs.readFile("src/server/World/Kit/CarBodies.luau")
	check(string.find(src, "noseFromProfile(heights)", 1, true) ~= nil and string.find(src, "flipped.Front = axisName(-fwd)", 1, true) ~= nil,
		"un coche sin asiento con el morro al revés se hace otra vez girado (Forward = «perfil»)")
	-- Todas las del tráfico y los aparcados saben de dónde sacaron el morro
	local okForward, bad = true, {}
	for _, t in CarBodies.library() do
		local f = t:GetAttribute("Forward")
		if not (f == "asiento" or f == "config" or f == "perfil" or f == "voladizo" or f == "cabina" or f == "por defecto") then
			okForward = false
			table.insert(bad, t.Name .. "=" .. tostring(f))
		end
	end
	check(okForward, "todas las carrocerías dicen de dónde sacaron el morro (asiento, Front, perfil, cabina; voladizo o por defecto solo sin rayos) " .. table.concat(bad, ", "))
end
local neonEuro = names["Brisa Uno"]
local _, euroHi = CarBodies.bounds(parts(neonEuro) :: any)
check(euroHi.Y > 4.5, "europeo escalado (techo a " .. string.format("%.1f", euroHi.Y) .. ")")

---------------------------------------------------------------------
print("▶ Un coche aparcado con malla")
local parked = CarModel.build(world, CF, RED, { Name = "ParkedCar", Variant = "Berlina", Lite = true })
local wheelsBefore = {}
for _, p in parts(parked) do
	if p.Name == "Wheel" or p.Name == "Rim" then
		table.insert(wheelsBefore, p.Name .. tostring(p.CFrame.Position))
	end
end
local okDress = CarBodies.dress(parked, CF, { Role = "Parked", Key = "1:2", Template = "Aurea Berlina" })
check(okDress and parked:GetAttribute("CarBody") == "Aurea Berlina", "dress: lleva la malla «Aurea Berlina»")
local wheelsAfter = {}
for _, p in parts(parked) do
	if p.Name == "Wheel" or p.Name == "Rim" then
		table.insert(wheelsAfter, p.Name .. tostring(p.CFrame.Position))
	end
end
table.sort(wheelsBefore)
table.sort(wheelsAfter)
check(#wheelsAfter == 8 and table.concat(wheelsBefore) == table.concat(wheelsAfter), "las ruedas (y llantas) no se mueven")
local body = parked:FindFirstChild("Body")
check(body and body.Transparency == 1 and body.CanCollide and body:GetAttribute("CarHidden"), "Body: invisible y sigue chocando")
local visibleBox = {}
for _, p in parked:GetChildren() do
	if p:IsA("BasePart") and p.Transparency < 1 and not p:GetAttribute("CarMesh") and p.CanCollide then
		table.insert(visibleBox, p.Name)
	end
end
check(#visibleBox == 0, "ninguna pieza de la carrocería de piezas se ve " .. table.concat(visibleBox, ","))
local lo, hi = meshBounds(parked, CF)
local head, tail = parked:FindFirstChild("Headlight"), parked:FindFirstChild("Taillight")
check(head and math.abs(localOf(head, CF).Z - lo.Z) < 1, ("faro en el morro de la malla (z %.2f, morro %.2f)"):format(head and localOf(head, CF).Z or 0, lo.Z))
check(tail and math.abs(localOf(tail, CF).Z - hi.Z) < 1, ("piloto en la cola de la malla (z %.2f, cola %.2f)"):format(tail and localOf(tail, CF).Z or 0, hi.Z))
check(head:HasTag("CarLight") and tail:HasTag("CarLight"), "las luces de aparcado siguen con su etiqueta CarLight")
check(parked:FindFirstChild("PlateRear") and parked:FindFirstChild("PlateFront"), "matrículas de delante y detrás")
local painted, notPainted = 0, 0
for _, p in parked:GetChildren() do
	if p:GetAttribute("CarZone") == "Primary" then
		if p.Color == RED then
			painted += 1
		else
			notPainted += 1
		end
	end
end
local chosenPaint = parked:GetAttribute("Paint")
painted, notPainted = 0, 0
for _, p in parked:GetChildren() do
	if p:GetAttribute("CarZone") == "Primary" then
		if p.Color == chosenPaint and p.Reflectance >= 0.15 then
			painted += 1
		else
			notPainted += 1
		end
	end
end
check(painted >= 2 and notPainted == 0 and table.find(CarBodies.Paints, chosenPaint), ("pintura de coche de verdad, con brillo (%d piezas)"):format(painted))
local glassOk, glassN = true, 0
for _, p in parked:GetChildren() do
	if p:GetAttribute("CarZone") == "Glass" then
		glassN += 1
		if not (p.Reflectance >= 0.25 and p.Transparency > 0.1 and p.Transparency < 0.6) then
			glassOk = false
		end
	end
end
check(glassN > 0 and glassOk, "cristal oscuro, algo transparente y con reflejo")
local tires = 0
for _, p in parked:GetChildren() do
	if p.Name == "TireMesh" then
		tires += 1
	end
end
check(tires >= 4 and parked:FindFirstChild("Wheel").Transparency == 1, ("neumáticos de malla en las 4 ruedas (%d piezas); los cilindros, invisibles"):format(tires))
check(#brandHits(parked) == 0, "coche aparcado sin marcas " .. table.concat(brandHits(parked), " | "))
local euroCarModel = CarModel.build(world, CF, RED, { Name = "ParkedCar", Variant = "Compacto", Lite = true })
CarBodies.dress(euroCarModel, CF, { Role = "Parked", Template = "Brisa Uno" })
local euroPainted = 0
for _, p in euroCarModel:GetChildren() do
	if p:GetAttribute("CarMesh") and p.Color == RED then
		euroPainted += 1
	end
end
check(euroPainted == 0 and names["Brisa Uno"]:GetAttribute("Paintable") == false, "las mallas con textura no se pintan (no pintables)")

---------------------------------------------------------------------
print("▶ Elección determinista y variada")
local a1 = CarBodies.choose("Parked", "10:20")
local a2 = CarBodies.choose("Parked", "10:20")
check(a1 == a2, "misma clave -> misma carrocería")
local seen, count = {}, 0
for i = 1, 60 do
	local t = CarBodies.choose("Parked", "k" .. i)
	if t and not seen[t.Name] then
		seen[t.Name] = true
		count += 1
	end
end
check(count >= 6, ("variedad en los aparcados: %d distintas"):format(count))
local playerOk = true
for i = 1, 30 do
	local t = CarBodies.choose("Player", "p" .. i, CarBodies.VariantTypes.Berlina)
	if not t or t:GetAttribute("Paintable") ~= true or t:GetAttribute("Type") ~= "Sedan" then
		playerOk = false
	end
end
check(playerOk, "el coche del jugador: siempre una berlina pintable")
local policeOk = true
for i = 1, 20 do
	local t = CarBodies.choose("Policia", "c" .. i)
	if not t or t:GetAttribute("Type") ~= "Policia" then
		policeOk = false
	end
end
check(policeOk, "la policía: solo coches patrulla")

---------------------------------------------------------------------
print("▶ El tuyo (Rides) y la patrulla")
local mine = Rides.build("Coche", nil, CF, Color3.fromRGB(40, 160, 80))
check(mine:GetAttribute("CarBody") ~= nil, "Rides.build(Coche): con malla " .. tostring(mine:GetAttribute("CarBody")))
local chassis, seat = Rides.prepare(mine, "Coche", CF)
check(chassis and seat and #mine:GetChildren() > 10, "Rides.prepare: base y asiento")
local welded, loose = 0, 0
for _, p in mine:GetChildren() do
	if p:IsA("BasePart") and p:GetAttribute("CarMesh") then
		if p:FindFirstChildWhichIsA("WeldConstraint") and not p.Anchored then
			welded += 1
		else
			loose += 1
		end
	end
end
check(welded > 0 and loose == 0, "la malla va soldada a la base")
local rideSeats = 0
for _, p in mine:GetChildren() do
	if p.Name == "RideSeat" then
		rideSeats += 1
	end
end
check(rideSeats == 3, "3 asientos de pasajero")
local infos = {}
for _, p in parts(mine) do
	table.insert(infos, { Name = p.Name, CFrame = CF:ToObjectSpace(p.CFrame), Size = p.Size })
end
local rig = WheelRig.find(infos, "Coche")
check(#rig.Wheels == 4 and rig.Steers, "WheelRig: 4 ruedas, las de delante giran con el volante")
local spinTires = 0
for _, w in rig.Wheels do
	for _, i in w.Spin do
		if infos[i].Name == "TireMesh" then
			spinTires += 1
		end
	end
end
check(spinTires >= 4, ("los neumáticos de malla giran con su rueda (%d)"):format(spinTires))
local interior = mine:FindFirstChild("Dashboard") and mine:FindFirstChild("FrontSeat")
check(interior, "el interior (salpicadero y asientos) se queda")
-- Taller: pinta la malla y no enseña las lunas de piezas
VehicleBuild.apply(mine, { V = 1, Body = "", Paint = "P_Rojo", Finish = "", Paint2 = "", Rims = "", RimColor = "", Tires = "", Tint = 2, Spoiler = "", BumperF = "", BumperR = "", Neon = "", Plate = "" }, { Kind = "Coche", Origin = CF })
local side = mine:FindFirstChild("SideWindow")
check(side and side.Transparency == 1, "taller con lunas tintadas: las lunas de piezas siguen escondidas")
VehicleBuild.clear(mine)
check(mine:FindFirstChild("Body").Transparency == 1 and side.Transparency == 1, "taller clear(): la carrocería de piezas sigue escondida")

local patrol = Rides.build("Patrulla", nil, CF, nil)
local tName = patrol:GetAttribute("CarBody")
check(tName == "Valmar Patrulla" or tName == "Valmar Patrulla Clásica", "patrulla con malla de policía: " .. tostring(tName))
local stripe = patrol:FindFirstChild("PoliceStripe")
local label = stripe and stripe:FindFirstChildWhichIsA("SurfaceGui") and stripe:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel")
check(label and label.Text == "POLICÍA", "rótulo «POLICÍA» en el costado")
local plo, phi = meshBounds(patrol, CF)
local sirenOk = true
for _, p in patrol:GetChildren() do
	if p.Name == "SirenBlue" or p.Name == "SirenRed" then
		local y = localOf(p, CF).Y
		if y < phi.Y - 0.6 or y > phi.Y + 1.5 then
			sirenOk = false
		end
	end
end
check(sirenOk and patrol:FindFirstChild("SirenBlue"), "sirenas sobre el techo de la malla")
check(patrol:HasTag("PoliceCar") and patrol:GetAttribute("Siren") == false, "sigue siendo un PoliceCar con sirena")
check(math.abs(localOf(stripe, CF).X) > phi.X - 0.6, "la franja va pegada al costado de la malla")
check(#brandHits(patrol) == 0, "patrulla sin marcas (ni «POLICE» ni «CHP») " .. table.concat(brandHits(patrol), " | "))
check(#brandHits(mine) == 0, "tu coche sin marcas")

-- Upgrade: el aparcado al cogerlo pasa a completo y conserva su malla
local up = CarModel.build(world, CF, RED, { Name = "ParkedCar", Variant = "Berlina", Lite = true })
CarBodies.dress(up, CF, { Role = "Parked", Template = "Toro Faena" })
CarModel.upgrade(up, CF)
check(up:GetAttribute("CarBody") == "Toro Faena" and up:FindFirstChild("CarShell") and up:FindFirstChild("Body").Transparency == 1, "al cogerlo (upgrade) conserva la misma malla")

---------------------------------------------------------------------
print("▶ Tráfico: plantillas con malla (Ambient.CarsMesh)")
local Ambient = load("src/server/World/Ambient")
local amb = Instance.new("Folder")
local carsF = Instance.new("Folder")
carsF.Name = "Cars"
carsF.Parent = amb
for i = 1, 4 do
	CarModel.build(carsF, CFrame.new(), RED, { Name = "Car" .. i, Variant = "Berlina" })
end
local taxi = CarModel.build(carsF, CFrame.new(), WHITE, { Name = "Taxi1", Variant = "Berlina" })
local sign = Instance.new("Part")
sign.Name = "TaxiSign"
sign.Size = Vector3.new(2.6, 0.7, 0.9)
sign.CFrame = CFrame.new(0, 5.65, 0.6)
sign.CanCollide = false
sign.Parent = taxi
local n = Ambient.meshCars(amb, CarBodies)
local meshF = amb:FindFirstChild("CarsMesh")
check(n == Ambient.MESH_CARS + 1 and meshF, ("CarsMesh: %d plantillas (con el taxi)"):format(n))
local meshNames = {}
for _, m in meshF:GetChildren() do
	meshNames[m:GetAttribute("CarBody") or "?"] = true
end
local distinct = 0
for _ in meshNames do
	distinct += 1
end
check(distinct >= 5, ("variedad en el tráfico: %d carrocerías"):format(distinct))
local taxiMesh = meshF:FindFirstChild("Taxi1")
check(taxiMesh and taxiMesh:FindFirstChild("TaxiSign") and taxiMesh:GetAttribute("CarBody"), "taxi con malla y su cartel")
check(#brandHits(meshF) == 0, "tráfico sin marcas")
check(#brandHits(world) == 0, "nada de lo construido tiene marcas")

---------------------------------------------------------------------
local traffic = fs.readFile("src/client/Controllers/Traffic.luau")
print("▶ Autobús, camiones y autocares")
local urb = names["Valmar Urbano"]
local hasCentury = false
for _, d in urb:GetDescendants() do
	if d:IsA("TextLabel") and string.find(d.Text, "CENTURY") then
		hasCentury = true
	end
end
check(not hasCentury, "el rótulo «CENTURY LINE 7701» del autobús no se copia")
local ulo, uhi = CarBodies.bounds(parts(urb) :: any)
check(math.abs(uhi.Z - ulo.Z - 34) < 3 and math.abs(uhi.X - ulo.X - 8.6) < 1.2, ("autobús escalado a nuestro autobús (%.1f × %.1f)"):format(uhi.X - ulo.X, uhi.Z - ulo.Z))
local bus = Rides.build("Autobus", nil, CF, Color3.fromRGB(200, 40, 45))
check(bus:GetAttribute("CarBody") == "Valmar Urbano", "Rides.build(Autobus): con la malla del autobús")
local doors, seats, visibleDoors = 0, 0, 0
for _, p in bus:GetChildren() do
	if p.Name == "BusDoor" then
		doors += 1
		if p.Transparency < 1 then
			visibleDoors += 1
		end
	elseif p:IsA("Seat") and p.Name == "PassengerSeat" then
		seats += 1
	end
end
check(doors == 4 and visibleDoors == 4, "las 4 hojas de puerta siguen (y se ven)")
check(seats > 10, ("los asientos de pasajeros siguen (%d)"):format(seats))
local dest = bus:FindFirstChild("DestinationSign")
local destLabel = dest and dest:FindFirstChildWhichIsA("SurfaceGui") and dest:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel")
local blo, bhi = meshBounds(bus, CF)
check(destLabel and string.find(destLabel.Text, "VALMAR") and math.abs(localOf(dest, CF).Z - blo.Z) < 1, "letrero de línea de Valmar en el morro de la malla")
check(bus:FindFirstChild("RearSign") and math.abs(localOf(bus:FindFirstChild("RearSign"), CF).Z - bhi.Z) < 1, "letrero de detrás en la cola de la malla")
local busChassis = Rides.prepare(bus, "Autobus", CF)
check(busChassis and bus:FindFirstChild("DriverSeat"), "Rides.prepare del autobús: base y asiento del conductor")
check(#brandHits(bus) == 0, "autobús sin marcas")
local truckT = names["Kestrel Reparto"]
check(truckT:GetAttribute("Forward") == "cabina", "camión: el morro por la cabina")
local cabZ
for _, p in parts(truckT) do
	if p.Name ~= "CarGlass" and p.Name ~= "CarBadge" and p.Size.Z < 9 then
		cabZ = p.CFrame.Position.Z
	end
end
check(cabZ and cabZ < -4, ("camión: la cabina queda delante (z %.1f)"):format(cabZ or 0))
local dirt = 0
for _, d in names["Toro Ruta"]:GetDescendants() do
	if d:IsA("Decal") or d:IsA("Texture") or d:IsA("BoolValue") then
		dirt += 1
	end
end
check(dirt == 0, "autocar sin suciedad (Decals/Textures) ni BoolValue")
local heavyF = amb:FindFirstChild("HeavyMesh")
check(heavyF and #heavyF:GetChildren() == Ambient.HEAVY, "Ambient.HeavyMesh: camiones y autocares para el tráfico")
local heavyOk, kinds = true, {}
for _, m in heavyF:GetChildren() do
	kinds[m:GetAttribute("CarBody")] = true
	local b = m:FindFirstChild("Body")
	if not (b and b.CanCollide and b.Transparency == 1 and m:FindFirstChild("Headlight") and m:FindFirstChild("Taillight") and m:GetAttribute("Kind") == "Pesado") then
		heavyOk = false
	end
end
check(heavyOk and kinds["Kestrel Reparto"] and kinds["Toro Ruta"], "pesados con caja de choque, faros y pilotos (camión y autocar)")
check(#brandHits(heavyF) == 0, "pesados sin marcas")
check(string.find(traffic, "HeavyMesh", 1, true) and string.find(traffic, "removeHeavy", 1, true), "el tráfico pone los pesados y los quita en Bajo")
local mineTires = 0
for _, p in mine:GetChildren() do
	if p.Name == "TireMesh" then
		mineTires += 1
	end
end
check(mineTires == 12, ("tu coche: la rueda completa de malla en las 4 ruedas (%d piezas)"):format(mineTires))

---------------------------------------------------------------------
print("▶ Aparcamientos: TODOS los coches con malla y variados")
local Props = load("src/server/World/Kit/Props")
local town = Instance.new("Folder")
town.Name = "Town"
local lotM = Instance.new("Model")
lotM.Name = "Parking"
lotM.Parent = town
for i = 0, 29 do
	Props.car(lotM, CFrame.new(1000 + (i % 10) * 10, 0.4, 500 + math.floor(i / 10) * 18))
end
for r = 1, 50 do
	local row = Instance.new("Folder")
	row.Name = "Calle" .. r
	row.Parent = town
	for i = 1, 8 do
		Props.car(row, CFrame.new(-2000 + r * 40, 0.4, i * 16) * CFrame.Angles(0, math.pi / 2, 0))
	end
end
local parkedAll, parkedMesh, near, nearMesh = 0, 0, 0, 0
local playerAt = Vector3.new(1050, 0, 520)
local partsSum = 0
for _, m in town:GetDescendants() do
	if m:IsA("Model") and m.Name == "ParkedCar" then
		parkedAll += 1
		local has = m:GetAttribute("CarBody") ~= nil
		if has then
			parkedMesh += 1
			local t = names[m:GetAttribute("CarBody")]
			partsSum += t and t:GetAttribute("Parts") or 0
		end
		local body = m:FindFirstChild("Body")
		if body and (body.CFrame.Position - playerAt).Magnitude < 768 then
			near += 1
			if has then
				nearMesh += 1
			end
		end
	end
end
check(parkedAll == 430 and parkedMesh == parkedAll, ("todos los aparcados con malla, sin tope de 320 (%d de %d)"):format(parkedMesh, parkedAll))
check(near >= 30 and nearMesh == near, ("los aparcados cerca de un jugador (radio de StreamingEnabled): %d de %d con malla"):format(nearMesh, near))
local lotBodies, lotPaints, lotN = {}, {}, 0
for _, m in lotM:GetChildren() do
	if m.Name == "ParkedCar" then
		lotN += 1
		lotBodies[m:GetAttribute("CarBody") or "?"] = true
		lotPaints[tostring(m:GetAttribute("Paint"))] = true
	end
end
local distinctLot, distinctPaint = 0, 0
for _ in lotBodies do
	distinctLot += 1
end
for _ in lotPaints do
	distinctPaint += 1
end
check(distinctLot >= 8, ("variedad en un aparcamiento: %d carrocerías distintas en %d coches"):format(distinctLot, lotN))
check(distinctPaint >= 6, ("y colores variados: %d"):format(distinctPaint))
local allBodies = {}
for _, m in town:GetDescendants() do
	if m.Name == "ParkedCar" and m:GetAttribute("CarBody") then
		allBodies[m:GetAttribute("CarBody")] = true
	end
end
local civil, civilSeen = 0, 0
for _, t in lib do
	local roles = t:GetAttribute("Roles")
	if type(roles) == "string" and table.find(string.split(roles, ","), "Parked") then
		civil += 1
		if allBodies[t.Name] then
			civilSeen += 1
		end
	end
end
check(civilSeen == civil, ("en la ciudad salen todas las carrocerías de aparcado (%d de %d)"):format(civilSeen, civil))
check(parkedMesh > 0 and partsSum / parkedMesh <= 22, ("los aparcados prefieren las ligeras: %.1f piezas por coche de media"):format(partsSum / math.max(parkedMesh, 1)))
local anyParked = lotM:FindFirstChild("ParkedCar")
check(anyParked:HasTag("CarMeshBody"), "los coches con malla llevan la etiqueta CarMeshBody (el cliente vigila que se vean)")
check(#brandHits(town) == 0, "aparcados sin marcas")

---------------------------------------------------------------------
print("▶ Tráfico en gráficos Bajo: malla ligera, no cajas")
local liteF = amb:FindFirstChild("CarsMeshLite")
check(liteF and #liteF:GetChildren() == Ambient.LITE_CARS, "Ambient.CarsMeshLite: plantillas para gráficos Bajo")
local lightest = CarBodies.lightest("Traffic")
local liteOk, liteNames = true, {}
for _, m in liteF and liteF:GetChildren() or {} do
	local t = names[m:GetAttribute("CarBody") or ""]
	liteNames[m:GetAttribute("CarBody") or "?"] = true
	if not t or not table.find(lightest, t) or not m:FindFirstChild("CarShell") and not m:FindFirstChild("CarTrim") then
		liteOk = false
	end
end
check(liteOk and #lightest > 0, "en Bajo, solo las carrocerías más ligeras (y con malla)")
check(string.find(traffic, "CarsMeshLite", 1, true) ~= nil, "el tráfico del cliente usa CarsMeshLite en gráficos Bajo")
check(string.find(traffic, "CarMeshBody", 1, true) ~= nil and string.find(traffic, "showBox", 1, true) ~= nil, "el cliente vuelve a enseñar la caja si la malla de un coche no carga")

---------------------------------------------------------------------
print("▶ Coches del pase de temporada con malla de verdad")
local PremiumVehicles = load("src/shared/PremiumVehicles")
local premiumCars = {}
for _, id in PremiumVehicles.List do
	local v = PremiumVehicles.get(id)
	if v.Kind ~= "Coche" then
		continue
	end
	local t = CarBodies.premiumTemplate(v)
	check(t ~= nil and t.Name == v.Bodies[1] and t:GetAttribute("Roles") == "Sport", ("%s -> %s"):format(v.Name, tostring(t and t.Name)))
	local car = Rides.build("Coche", nil, CF, nil, { Model = id })
	premiumCars[id] = car
	check(car:GetAttribute("CarBody") == (t and t.Name) and car:GetAttribute("PremiumBody") == true and car:GetAttribute("PremiumModel") == id, v.Name .. ": Rides.build lleva la malla deportiva")
	local paint = Color3.fromRGB(v.Paint[1], v.Paint[2], v.Paint[3])
	local shells, painted = 0, 0
	local procVisible = {}
	local wheelsVisible, rims = 0, 0
	for _, p in car:GetChildren() do
		if p:IsA("BasePart") then
			if p:GetAttribute("CarZone") == "Primary" then
				shells += 1
				if p.Color == paint then
					painted += 1
				end
			end
			if (p.Name == "Panel" or p.Name == "Wing" or p.Name == "Spoiler" or p.Name == "Roof" or p.Name == "Livery" or p.Name == "Windshield") and p.Transparency < 1 then
				table.insert(procVisible, p.Name)
			end
			if p.Name == "Wheel" and p.Transparency == 0 then
				wheelsVisible += 1
			elseif p.Name == "Rim" then
				rims += 1
			end
		end
	end
	check(shells > 0 and painted == shells, ("%s: pintura del pase en la malla (%d piezas)"):format(v.Name, shells))
	check(#procVisible == 0, v.Name .. ": nada de la carrocería de piezas se ve " .. table.concat(procVisible, ","))
	check(wheelsVisible == 4 and rims >= 4, v.Name .. ": sus ruedas con llantas de verdad")
	local tier = PremiumVehicles.TierLook[v.Rarity]
	local hasChrome, hasGlow, hasUnder = car:FindFirstChild("PremiumChrome") ~= nil, car:FindFirstChild("GlowLine") ~= nil, car:FindFirstChild("Underglow") ~= nil
	check(hasChrome == (tier.Chrome == true) and (hasGlow or not tier.GlowLines) and (hasUnder or not tier.Underglow), ("%s (%s): cromo %s, líneas de luz %s, neón bajo %s"):format(v.Name, v.Rarity, tostring(hasChrome), tostring(hasGlow), tostring(hasUnder)))
	local head = car:FindFirstChild("Headlight")
	local plo = meshBounds(car, CF)
	check(head and math.abs(localOf(head, CF).Z - plo.Z) < 1.2, v.Name .. ": faros en el morro de la malla")
	check(#brandHits(car) == 0, v.Name .. ": sin marcas " .. table.concat(brandHits(car), " | "))
end
local voltex = premiumCars.VoltexGTR
Rides.prepare(voltex, "Coche", CF)
local loose = 0
for _, p in voltex:GetChildren() do
	if p:IsA("BasePart") and p:GetAttribute("CarMesh") and p.Anchored then
		loose += 1
	end
end
check(loose == 0, "el coche del pase preparado para conducir: la malla va soldada")
local moto = Rides.build("Moto", nil, CF, nil, { Model = "Storm" })
check(moto:GetAttribute("CarBody") == nil and moto:GetAttribute("PremiumModel") == "Storm", "las motos del pase siguen siendo de piezas")
local bpService = fs.readFile("src/server/Services/BattlePassService.luau")
check(string.find(bpService, "Rides.build(def.Kind", 1, true) ~= nil and string.find(bpService, "Model = def.Model", 1, true) ~= nil, "las vistas previas del pase (BattlePassPreviews) se hacen con Rides.build: el mismo coche con malla")

---------------------------------------------------------------------
print("▶ Ningún vehículo invisible")
local function visibleMesh(m: Instance): boolean
	local opaque = {}
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and p:GetAttribute("CarMesh") and p.Transparency < 0.5 and p:GetAttribute("CarZone") ~= "Glass" and p.Name ~= "TireMesh" and p.Name ~= "CarBadge" and p:GetAttribute("CarZone") ~= "Accent" then
			table.insert(opaque, p)
		end
	end
	return #opaque > 0 and CarBodies.coverage(opaque) >= CarBodies.MinCover
end
local function anyVisible(m: Instance): boolean
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 0.5 and math.max(p.Size.X, p.Size.Y, p.Size.Z) >= 3 then
			return true
		end
	end
	return false
end
local invisible = {}
local vehicles = {}
for _, m in town:GetDescendants() do
	if m.Name == "ParkedCar" then
		table.insert(vehicles, m)
	end
end
for _, f in { meshF, liteF, heavyF } do
	for _, m in f and f:GetChildren() or {} do
		table.insert(vehicles, m)
	end
end
for _, m in { parked, mine, patrol, bus, up, euroCarModel } do
	table.insert(vehicles, m)
end
for _, m in premiumCars do
	table.insert(vehicles, m)
end
local origOk = true
for _, m in vehicles do
	if m:GetAttribute("CarBody") and not visibleMesh(m) then
		table.insert(invisible, m.Name .. "(" .. tostring(m:GetAttribute("CarBody")) .. ")")
	elseif not anyVisible(m) then
		table.insert(invisible, m.Name)
	end
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and p:GetAttribute("CarHidden") and m:GetAttribute("Kind") ~= "Pesado" and type(p:GetAttribute("CarOrigT")) ~= "number" then
			origOk = false
		end
	end
end
check(#invisible == 0, ("cada vehículo tiene una carrocería que se ve (%d mirados) %s"):format(#vehicles, table.concat(invisible, ", "):sub(1, 200)))
check(origOk, "cada pieza escondida guarda cómo era (CarOrigT) para volver a verse si la malla no carga")
for _, t in lib do
	check((t:GetAttribute("Cover") or 0) >= CarBodies.MinCover, ("%s: la carrocería tapa su silueta (%.2f)"):format(t.Name, t:GetAttribute("Cover") or 0))
end

print("▶ Rendimiento")
local over = {}
for _, t in lib do
	local tris = t:GetAttribute("Tris")
	local cap = if t:GetAttribute("Heavy") then CarBodies.MaxHeavyTris else CarBodies.MaxTris
	if t:GetAttribute("Hero") ~= true and (type(tris) ~= "number" or tris > cap) then
		table.insert(over, t.Name)
	end
	local maxC = t:GetAttribute("MaxCopies")
	if t:GetAttribute("Hero") == true and not (type(maxC) == "number" and maxC > 0 and maxC <= 6) then
		table.insert(over, t.Name .. " sin tope de copias")
	end
end
check(#over == 0, "tope de triángulos por coche (las pesadas, con pocas copias) " .. table.concat(over, ","))
local shadows = 0
for _, t in lib do
	for _, p in parts(t, true) do
		if p.CastShadow and math.max(p.Size.X, p.Size.Y, p.Size.Z) < CarBodies.ShadowSize then
			shadows += 1
		end
	end
end
check(shadows == 0, "sin sombras en las piezas pequeñas")
check(string.find(traffic, "CarsMesh", 1, true) and string.find(traffic, '"Low"', 1, true), "el tráfico usa CarsMesh (y CarsMeshLite en gráficos Bajo)")
local src = fs.readFile("src/server/World/Kit/CarBodies.luau")
check(string.find(src, "pcall", 1, true) and string.find(src, "LoadAssetAsync", 1, true), "carga en vivo con pcall (AssetService)")
for _, id in { 9432856072, 10935800149, 10897563593, 97902046131324, 4573650411, 15418880736, 18912826861, 16893586720, 130974691456028, 18577576400, 131247677717086, 16358361587, 95641562400547, 4128265113, 17601139281, 8448337398 } do
	check(string.find(src, tostring(id), 1, true) ~= nil, "el id " .. id .. " está (usado o descartado con su porqué)")
end
local doc = if fs.isFile("docs/assets-implementados.md") then fs.readFile("docs/assets-implementados.md") else ""
check(string.find(doc, "## Coches", 1, true) ~= nil, "docs/assets-implementados.md tiene la sección «Coches»")

print("")
if failures > 0 then
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
