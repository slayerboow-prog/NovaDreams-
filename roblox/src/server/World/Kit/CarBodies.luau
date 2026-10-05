-- CarBodies: carrocerías DE VERDAD (mallas 3D) para los coches del juego, sacadas de los packs que
-- pasó el dueño (docs/modelos-oficiales-2.md, docs/assets-usuario-3.md, -4.md y -5.md). Ver la
-- sección «Coches» de docs/assets-implementados.md: qué id se usa para qué y cuáles no, y por qué.
--
--   * Al arrancar el servidor (Ambient.publish lo lanza en un hilo aparte) se cargan los packs con
--     AssetService:LoadAssetAsync (y si no, InsertService:LoadAsset), todo con pcall. De cada coche
--     del pack se copian SOLO sus piezas visibles de la carrocería (MeshPart / Part, con su
--     SurfaceAppearance o su SpecialMesh): ni scripts, ni Decals, ni Textures, ni SurfaceGuis, ni
--     sonidos, ni asientos, ni ruedas, ni atributos. Nunca se mete el pack en el workspace.
--   * SIN MARCAS: se tira toda pieza con nombre de marca, logo, insignia o matrícula; las que quedan
--     se renombran (CarShell / CarGlass / CarTrim) y cada carrocería lleva un nombre y una marca
--     INVENTADOS (Aurea, Kestrel, Brisa, Toro, Valmar Motors) en dos placas pequeñas (CarBadge) que
--     tapan el sitio del logo de delante y de detrás.
--   * Cada carrocería se gira (morro a −Z: el asiento del conductor del pack, o lo que diga Front, o
--     el voladizo y la silueta), se escala a la caja de nuestros coches (Rides.Spec.Coche: 6,2 × 13,5,
--     con el techo a la altura de su tipo) haciendo coincidir sus pasos de rueda con nuestras ruedas
--     (z = ±4,3) y queda como plantilla (ServerStorage.CarBodies), con sus medidas (morro, cola,
--     costado, techo) medidas con rayos cuando se puede.
--   * CarBodies.dress(modelo, cf, opciones) cambia la carrocería de piezas de un coche (CarModel) por
--     la malla: se quedan nuestras ruedas (WheelRig: giran y viran), asientos, interior, matrículas,
--     luces (faros, pilotos, intermitentes, marcha atrás: llevadas al morro y la cola de la malla),
--     rótulos de policía y taxi (al costado y al techo de la malla) y las piezas del taller (Mod_).
--     La caja de choque de siempre (Body, Nose, parachoques, lunas…) se queda INVISIBLE: misma
--     colisión, mismos nombres. La malla no choca. La pintura (color de Body) va a las piezas
--     pintables (CarZone = "Primary"); las que tienen textura no se pintan (se elige otra).
--   * Elección determinista (misma clave -> misma carrocería) y por papel: Parked (aparcados),
--     Traffic (tráfico del cliente), Player (el tuyo: solo pintables), Policia, Taxi.
--   * Rendimiento: tope de triángulos por coche (MaxTris, salvo las «Hero» con tope de copias),
--     tope de piezas por plantilla, RenderFidelity Automatic, sin sombra en piezas pequeñas, sin
--     colisión ni consultas. En gráficos Bajo el tráfico del cliente usa la carrocería simple.
--   * Si la carga falla (o en Lune), no cambia nada: los coches siguen siendo los de piezas.

local CarBodies = {}

CarBodies.MaxTris = 26000 -- triángulos por coche (los «Hero» tienen su propio tope y pocas copias)
CarBodies.MaxHeavyTris = 40000 -- autobús, autocar y camión (pocos a la vez)
CarBodies.MaxParked = 320 -- coches aparcados con malla como mucho (el resto, carrocería simple)
CarBodies.Batch = 12 -- coches que se cambian por tanda (luego task.wait)
CarBodies.ShadowSize = 2.5 -- solo dan sombra las piezas que miden al menos esto
CarBodies.TireParts = 6 -- piezas de malla por rueda como mucho (neumático, llanta, buje…)

-- Aspecto realista (no de plástico). Pintura: brillo de coche (Reflectance) o el MaterialVariant de
-- pintura de coche de Modern City si está en MaterialService. Cristal: oscuro, algo transparente y
-- con reflejo. Molduras claras: cromo. Las texturas (TextureID) y el PBR (SurfaceAppearance) de cada
-- malla se quedan siempre.
CarBodies.Look = {
	Paint = { Material = "SmoothPlastic", Reflectance = 0.2, VariantReflectance = 0.08 },
	Glass = { Color = Color3.fromRGB(22, 28, 34), Transparency = 0.35, Reflectance = 0.3 },
	Chrome = { Material = "Metal", Reflectance = 0.35 },
}
-- Colores de verdad de coche (aparcados y tráfico): plata, blancos, negros, grafito, azules, rojos…
CarBodies.Paints = {
	Color3.fromRGB(196, 199, 204), -- plata
	Color3.fromRGB(236, 236, 232), -- blanco
	Color3.fromRGB(245, 243, 236), -- blanco perla
	Color3.fromRGB(22, 23, 26), -- negro
	Color3.fromRGB(78, 82, 88), -- grafito
	Color3.fromRGB(128, 132, 138), -- gris
	Color3.fromRGB(24, 44, 92), -- azul marino
	Color3.fromRGB(46, 92, 160), -- azul
	Color3.fromRGB(122, 20, 28), -- granate
	Color3.fromRGB(176, 28, 32), -- rojo
	Color3.fromRGB(32, 70, 52), -- verde inglés
	Color3.fromRGB(176, 160, 132), -- beige
	Color3.fromRGB(92, 64, 46), -- marrón
	Color3.fromRGB(214, 160, 40), -- ocre
}
-- Decals que son logos de marca (vistos en los docs): se tiran. Los demás Decals (detalles) se quedan
-- salvo que su nombre diga marca, logo, matrícula…
CarBodies.LogoIds = {
	[135553045] = true, [9006570790] = true, [249347085] = true, [463207748] = true, [105166659] = true,
	[130853852] = true, [105170387] = true, [8242816677] = true, [9002939634] = true, [296460823] = true,
	[15641588335] = true, [135513876] = true,
}

-- Nuestros coches (Kit/CarModel): ruedas en z = ±4,3, y = 1,3; caja 6,2 × 13,5
local WHEEL_Z, WHEEL_Y, WHEEL_X = 4.3, 1.3, 2.8
local CAR_W, CAR_L = 6.2, 13.5

-- Tipos de carrocería: largo y altura del techo que se buscan
CarBodies.Types = {
	Sedan = { Length = 13.5, Roof = 5.3 },
	Compacto = { Length = 13.0, Roof = 5.4 },
	SUV = { Length = 13.8, Roof = 6.1 },
	Pickup = { Length = 14.2, Roof = 6.0 },
	Furgoneta = { Length = 14.2, Roof = 6.6 },
	Policia = { Length = 13.8, Roof = 5.4 },
	-- Pesados (no son coches): autobús urbano (encima del nuestro, Rides «Autobus»), camión de reparto
	-- y autocar (tráfico, Ambient.HeavyMesh)
	Autobus = { Length = 34, Roof = 9.8, Width = 8.6 },
	Reparto = { Length = 24, Roof = 10.5, Width = 7.8 },
	Autocar = { Length = 30, Roof = 11.4, Width = 8.4 },
}
-- Carrocería de CarModel -> tipos de malla para el coche del jugador
CarBodies.VariantTypes = { Berlina = { "Sedan" }, Compacto = { "Compacto", "Sedan" }, Todoterreno = { "SUV", "Pickup", "Sedan" } }
-- Altura del techo de la carrocería de piezas (para subir rótulos del techo a la malla)
local BOX_ROOF = { Berlina = 5.3, Compacto = 5.4, Todoterreno = 6.1 }

-- Marcas inventadas (nunca una real)
CarBodies.Brands = { "AUREA", "KESTREL", "BRISA", "TORO", "VALMAR MOTORS" }

--[[ Fuentes (ids de la Tienda). Cada Pick: Match = texto en el nombre del coche dentro del pack (en
minúsculas; "" = el primero), Name = nombre inventado, Brand, Type, Roles, Weight, Tris (estimados
por coche, de los docs), MaxParts (se quedan las N piezas más grandes), MaxCopies, Front ("-Z", "+Z",
"-X", "+X": hacia dónde mira el morro en el pack, si se sabe). Fallback = otros ids con el MISMO
contenido (se prueban si el primero no carga). ]]
local CIVIL = { "Parked", "Traffic" }
local CIVIL_PLAYER = { "Parked", "Traffic", "Player", "Taxi" }
CarBodies.Sources = {
	-- Oficiales de Roblox (usuario 1, avalados): carrocería «Body», 14 scripts por coche que se tiran
	{ Id = 6418239833, Pack = "Oficial", Picks = { { Match = "", Name = "Aurea Berlina", Brand = "AUREA", Type = "Sedan", Roles = CIVIL_PLAYER, Tris = 15000 } } },
	{ Id = 6418234850, Pack = "Oficial", Picks = { { Match = "", Name = "Kestrel Sierra", Brand = "KESTREL", Type = "SUV", Roles = { "Parked", "Traffic", "Player" }, Tris = 14300 } } },
	{ Id = 6418225759, Pack = "Oficial", Picks = { { Match = "", Name = "Toro Faena", Brand = "TORO", Type = "Pickup", Roles = { "Parked", "Traffic", "Player" }, Tris = 16800 } } },
	{ Id = 6433316269, Pack = "Oficial", Picks = { { Match = "", Name = "Brisa Carga", Brand = "BRISA", Type = "Furgoneta", Roles = CIVIL, Tris = 10200 } } },
	{ Id = 6418230807, Pack = "Oficial", Picks = { { Match = "", Name = "Valmar Patrulla", Brand = "VALMAR MOTORS", Type = "Policia", Roles = { "Policia" }, Tris = 19000, Weight = 3 } } },
	-- Semi-Realistic Car Pack (SubXero_X; las dos copias de YouCanCallMeCouch5 traen lo mismo y solo
	-- se usan si el original no carga). A-Chassis: Body/…/Paint pintable, Wheels/FL…, DriveSeat.
	-- No se usan los dos con «Protector» (los deportivos japoneses) ni los de anime.
	{
		Id = 9432856072,
		Fallback = { 10935800149, 10897563593 },
		Pack = "SemiRealistic",
		Picks = {
			{ Match = "camry", Name = "Aurea Serena", Brand = "AUREA", Type = "Sedan", Roles = CIVIL_PLAYER, Tris = 16000, MaxParts = 60 },
			{ Match = "suburban", Name = "Kestrel Ranchera", Brand = "KESTREL", Type = "SUV", Roles = CIVIL, Tris = 15000, MaxParts = 60 },
			{ Match = "c1500", Name = "Toro Campo", Brand = "TORO", Type = "Pickup", Roles = CIVIL, Tris = 15000, MaxParts = 60 },
			{ Match = "corolla", Name = "Brisa Sprint", Brand = "BRISA", Type = "Compacto", Roles = CIVIL, Tris = 12000, MaxParts = 60 },
			{ Match = "fury", Name = "Valmar Clásico", Brand = "VALMAR MOTORS", Type = "Sedan", Roles = CIVIL, Tris = 9000, MaxParts = 60 },
		},
	},
	-- «mesh pack» de Teddy_FV: 11 coches europeos muy ligeros (~4 800 tris) con textura (no se pintan)
	{
		Id = 97902046131324,
		Pack = "Europeos",
		Picks = {
			{ Match = "206", Name = "Brisa Uno", Brand = "BRISA", Type = "Compacto", Roles = CIVIL, Tris = 4800, Weight = 2 },
			{ Match = "hiace", Name = "Toro Reparto", Brand = "TORO", Type = "Furgoneta", Roles = CIVIL, Tris = 4800, Weight = 2 },
			{ Match = "astra", Name = "Aurea Nube", Brand = "AUREA", Type = "Compacto", Roles = CIVIL, Tris = 4800, Weight = 2 },
			{ Match = "almera", Name = "Kestrel Alba", Brand = "KESTREL", Type = "Sedan", Roles = CIVIL, Tris = 4800, Weight = 2 },
			{ Match = "avensis", Name = "Aurea Paseo", Brand = "AUREA", Type = "Sedan", Roles = CIVIL, Tris = 4800, Weight = 2 },
			{ Match = "aclass", Name = "Valmar Mini", Brand = "VALMAR MOTORS", Type = "Compacto", Roles = CIVIL, Tris = 4800, Weight = 2 },
			{ Match = "vectra", Name = "Kestrel Vela", Brand = "KESTREL", Type = "Sedan", Roles = CIVIL, Tris = 4800, Weight = 2 },
			{ Match = "golf", Name = "Brisa Ola", Brand = "BRISA", Type = "Compacto", Roles = CIVIL, Tris = 4800, Weight = 2 },
			{ Match = "1995", Name = "Toro Familia", Brand = "TORO", Type = "Furgoneta", Roles = CIVIL, Tris = 4800, Weight = 2 },
			{ Match = "2004", Name = "Toro Familia Plus", Brand = "TORO", Type = "Furgoneta", Roles = CIVIL, Tris = 4800, Weight = 2 },
			{ Match = "primera", Name = "Kestrel Lince", Brand = "KESTREL", Type = "Sedan", Roles = CIVIL, Tris = 4800, Weight = 2 },
		},
	},
	-- Pack de policía de California (Xollare): solo UN coche (el sedán clásico), simplificado a sus
	-- piezas más grandes, sin rótulos (se pone «POLICÍA») ni sus 292 scripts. Pocas copias.
	{ Id = 4573650411, Pack = "Patrullas", Picks = { { Match = "crown", Name = "Valmar Patrulla Clásica", Brand = "VALMAR MOTORS", Type = "Policia", Roles = { "Policia" }, Tris = 34000, MaxParts = 45, MaxCopies = 3, Hero = true } } },
	-- Berlina importada (dinhtrung3): muy pesada (280 000 tris): simplificada y solo 4 aparcadas
	{ Id = 15418880736, Pack = "Berlina", Picks = { { Match = "", Name = "Aurea Lumen", Brand = "AUREA", Type = "Sedan", Roles = { "Parked" }, Tris = 90000, MaxParts = 40, MaxCopies = 4, Hero = true } } },
}
-- Reemplazos LIMPIOS (docs/assets-reemplazos.md, filas 7–10)
table.insert(CarBodies.Sources, {
	-- Autobús urbano (2races): 5 mallas, sin logos. Su malla «Decals» (el rótulo «CENTURY LINE 7701»)
	-- no se copia: se ven nuestros letreros de línea de Valmar.
	Id = 16358361587,
	Pack = "Autobus",
	Picks = { { Match = "", Name = "Valmar Urbano", Brand = "VALMAR MOTORS", Type = "Autobus", Roles = { "Bus" }, Tris = 9062, Heavy = true } },
})
table.insert(CarBodies.Sources, {
	-- Autocar (yiypoo1024): 19 mallas, sin logos; fuera sus Decals y Textures de suciedad
	Id = 95641562400547,
	Pack = "Autocar",
	Picks = { { Match = "", Name = "Toro Ruta", Brand = "TORO", Type = "Autocar", Roles = { "Heavy" }, Tris = 30649, Heavy = true, KeepWheels = true, NoDecals = true, FrontBy = "bus" } },
})
table.insert(CarBodies.Sources, {
	-- Camión caja (bearduckmonkey): cabina, caja y cristal, blanco y sin logos
	Id = 4128265113,
	Pack = "Reparto",
	Picks = { { Match = "", Name = "Kestrel Reparto", Brand = "KESTREL", Type = "Reparto", Roles = { "Heavy" }, Tris = 8771, Heavy = true, KeepWheels = true, NoDecals = true, FrontBy = "cab", Weight = 2 } },
})
-- Rueda completa (neumático + llanta) para el coche del jugador, la policía y los taxis; si no carga,
-- el neumático solo (con nuestra llanta)
CarBodies.WheelSources = {
	{ Id = 17601139281, Name = "Rueda completa", KeepRim = false, Tris = 4392 },
	{ Id = 8448337398, Name = "Neumático", KeepRim = true, Tris = 7200 },
}
CarBodies.WheelRoles = { Player = true, Policia = true, Taxi = true }

-- Ids que se miraron y NO se usan (el porqué, en docs/assets-implementados.md)
CarBodies.Skipped = {
	[18912826861] = "autobús: 255 000 tris y logo de empresa real; reemplazado por 16358361587",
	[16893586720] = "autocar: 1 804 piezas de bloques; reemplazado por 95641562400547",
	[130974691456028] = "camión caja: puerta trasera (familia 3); reemplazado por 4128265113",
	[18577576400] = "«NOT MINE»: robado, todo deportivos de marca y Protector 2.0",
	[131247677717086] = "neumáticos apilados en una malla y puertas traseras; reemplazado por 17601139281 / 8448337398",
}

-- Nombres que NUNCA se copian (marcas, logos, matrículas, ruedas…) — se mira en minúsculas
local JUNK_WORDS = {
	"badge", "logo", "emblem", "brand", "decal", "sticker", "plate", "license", "licence", "billboard",
	"wheel", "tire", "tyre", "rim", "brake", "caliper", "hub", "axle", "spring", "susp", "hitbox", "collision",
	"seat", "steer", "driver", "passenger", "exhaustflame", "smoke", "radio",
}
-- Marcas reales (también lo mira scripts/test-carbodies.luau en todo lo construido)
CarBodies.RealBrands = {
	"hyundai", "toyota", "ford", "chevrolet", "chevy", "bmw", "mercedes", "audi", "honda", "nissan", "tesla",
	"thaco", "chp", "ferrari", "lamborghini", "porsche", "volkswagen", "vw ", "kia", "dodge", "jeep", "gmc",
	"pontiac", "plymouth", "peugeot", "opel", "vauxhall", "renault", "citroen", "fiat", "seat ", "skoda", "mazda",
	"subaru", "mitsubishi", "lexus", "bugatti", "jaguar", "aston", "cadillac", "buick", "chrysler", "fleetwood",
	"supra", "skyline", "camry", "corolla", "silverado", "suburban", "elantra", "hiace", "golf", "astra",
	"vectra", "avensis", "almera", "primera", "sharan", "charger", "challenger", "hellcat", "crown vic",
	"explorer", "firebird", "trueno", "highway patrol", "california", "brembo", "vossen", "yokohama", "momo",
}
local LOGO_WORDS = { "badge", "logo", "emblem", "brand", "sticker", "plate", "license", "licence", "billboard", "text", "name", "police", "sheriff", "patrol" }
local WHEEL_NAMES = { fl = true, fr = true, rl = true, rr = true, lf = true, rf = true, lr = true, rr2 = true }

-- Partes de nuestro coche (CarModel) y qué se hace con ellas al ponerle malla
local KEEP = {
	Wheel = true, Rim = true, Spoke = true, Hub = true, Chassis = true,
	Dashboard = true, DashScreen = true, Steering = true, FrontSeat = true, FrontSeatBack = true,
	Headrest = true, RearBench = true, RearBenchBack = true,
}
local FRONT = { Headlight = "Lamp", HeadlightRight = "Lamp", IndicatorFront = "Lamp", PlateFront = "Mid", PushBar = "Mid" }
local REAR = { Taillight = "Lamp", IndicatorRear = "Lamp", Reverse = "Lamp", PlateRear = "Mid" }
local SIDE = { PoliceStripe = true, PoliceCheck = true, TaxiBand = true }
local ROOF = { LightBarBase = true, SirenBlue = true, SirenRed = true, Antenna = true, TaxiSign = true, TaxiLight = true }

---------------------------------------------------------------------
-- Estado
---------------------------------------------------------------------
local carPaintVariant
local library: { Model } = {}
local wheelTemplate: Folder? = nil -- rueda de malla (WheelSources), centrada y con el eje en X
local copies: { [string]: number } = {}
local parkedCount = 0
local pending: { { Model: Model, Cf: CFrame, Opts: { [string]: any }, Fn: any? } } = {}
local readyCallbacks: { () -> () } = {}
CarBodies.State = "idle" -- idle | loading | ready | failed

function CarBodies.reset()
	wheelTemplate = nil
	library = {}
	copies = {}
	parkedCount = 0
	pending = {}
	readyCallbacks = {}
	CarBodies.State = "idle"
end

function CarBodies.library(): { Model }
	return library
end
function CarBodies.wheel(): Folder?
	return wheelTemplate
end

function CarBodies.ready(): boolean
	return CarBodies.State == "ready" and #library > 0
end

-- fn() cuando las carrocerías estén listas (ya, si lo están). No se llama si la carga falla.
function CarBodies.onReady(fn: () -> ())
	if CarBodies.ready() then
		task.spawn(fn)
	else
		table.insert(readyCallbacks, fn)
	end
end

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
local function lower(s: string): string
	return string.lower(s)
end

local function hasWord(name: string, words: { string }): boolean
	local n = lower(name)
	for _, w in words do
		if string.find(n, w, 1, true) then
			return true
		end
	end
	return false
end

function CarBodies.isBrand(text: string): boolean
	return hasWord(" " .. text .. " ", CarBodies.RealBrands)
end

-- Hash FNV-1a de un texto (elección determinista)
function CarBodies.hash(key: any): number
	local s = tostring(key)
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = (h * 16777619) % 4294967296
	end
	return h
end

-- Caja (en el espacio de «frame») de unas piezas, contando su giro
local function bounds(parts: { BasePart }, frame: CFrame?): (Vector3, Vector3)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	local inv = if frame then frame:Inverse() else CFrame.new()
	for _, p in parts do
		local cf = inv * p.CFrame
		local s = p.Size / 2
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local e = Vector3.new(
			math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
			math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z,
			math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z
		)
		local c = cf.Position
		lo = Vector3.new(math.min(lo.X, c.X - e.X), math.min(lo.Y, c.Y - e.Y), math.min(lo.Z, c.Z - e.Z))
		hi = Vector3.new(math.max(hi.X, c.X + e.X), math.max(hi.Y, c.Y + e.Y), math.max(hi.Z, c.Z + e.Z))
	end
	return lo, hi
end
CarBodies.bounds = bounds

local function isWheelPart(p: Instance, root: Instance): boolean
	local n = lower(p.Name)
	if WHEEL_NAMES[n] or string.find(n, "wheel", 1, true) or string.find(n, "tire", 1, true) or string.find(n, "tyre", 1, true) then
		return true
	end
	local a = p.Parent
	while a and a ~= root do
		local an = lower(a.Name)
		if an == "wheels" or WHEEL_NAMES[an] or string.find(an, "wheel", 1, true) then
			return true
		end
		a = a.Parent
	end
	return false
end

---------------------------------------------------------------------
-- Coches dentro de un pack
---------------------------------------------------------------------
-- Un coche es un Model/Folder con un hijo «Body», un asiento de conductor o (pack de mallas) con al
-- menos 3 MeshPart sueltas. No se baja dentro de un coche ya encontrado.
local function isCarRoot(x: Instance): boolean
	if not (x:IsA("Model") or x:IsA("Folder")) or x.Name == "Body" then
		return false
	end
	if x:FindFirstChild("Body") or x:FindFirstChildWhichIsA("VehicleSeat") or x:FindFirstChild("DriveSeat") then
		return true
	end
	local meshes = 0
	for _, c in x:GetChildren() do
		if c:IsA("MeshPart") then
			meshes += 1
		end
	end
	return meshes >= 3
end

function CarBodies.findCars(pack: Instance): { Instance }
	local out = {}
	local function walk(x: Instance)
		for _, c in x:GetChildren() do
			if isCarRoot(c) then
				table.insert(out, c)
			elseif #c:GetChildren() > 0 and not c:IsA("BasePart") then
				walk(c)
			end
		end
	end
	if isCarRoot(pack) then
		table.insert(out, pack)
	else
		walk(pack)
	end
	return out
end

-- Piezas de la carrocería, ruedas (para encajar) y asiento del conductor de un coche del pack
local function carParts(car: Instance, keepWheels: boolean?): ({ BasePart }, { BasePart }, BasePart?)
	local bodyRoot: Instance = car
	local body = car:FindFirstChild("Body")
	if body and not body:IsA("BasePart") then
		bodyRoot = body
	end
	local shell, wheels = {}, {}
	local seat: BasePart? = nil
	for _, d in car:GetDescendants() do
		if d:IsA("VehicleSeat") or (d:IsA("BasePart") and d.Name == "DriveSeat") then
			seat = seat or d
		end
	end
	for _, d in car:GetDescendants() do
		if not d:IsA("BasePart") or d:IsA("Seat") or d:IsA("VehicleSeat") or d:IsA("Terrain") then
			continue
		end
		if isWheelPart(d, car) then
			if d.Transparency < 0.98 then
				table.insert(wheels, d)
				if keepWheels and not CarBodies.isBrand(d.Name) then
					table.insert(shell, d) -- (autocar: sus ruedas de malla se quedan, no lleva las nuestras)
				end
			end
			continue
		end
		if bodyRoot ~= car and not d:IsDescendantOf(bodyRoot) and not (body and d == body) then
			continue
		end
		if d.Transparency >= 0.98 or hasWord(d.Name, JUNK_WORDS) or CarBodies.isBrand(d.Name) then
			continue
		end
		local s = d.Size
		if math.max(s.X, s.Y, s.Z) < 0.05 then
			continue
		end
		table.insert(shell, d)
	end
	return shell, wheels, seat
end

-- Ruedas -> centros por esquina (en el espacio de «frame»): {FL, FR, RL, RR} o nil
local function wheelCenters(wheels: { BasePart }, frame: CFrame): { Vector3 }?
	if #wheels < 4 then
		return nil
	end
	local inv = frame:Inverse()
	local sum = Vector3.zero
	for _, w in wheels do
		sum += (inv * w.CFrame).Position
	end
	local mid = sum / #wheels
	local quads = {}
	for _, w in wheels do
		local p = (inv * w.CFrame).Position
		local key = (if p.X < mid.X then "L" else "R") .. (if p.Z < mid.Z then "F" else "B")
		local q = quads[key] or { Sum = Vector3.zero, N = 0, R = 0, Parts = {} }
		q.Sum += p
		q.N += 1
		table.insert(q.Parts, w)
		q.R = math.max(q.R, math.max(w.Size.X, w.Size.Y, w.Size.Z) / 2)
		quads[key] = q
	end
	local out = {}
	for _, key in { "LF", "RF", "LB", "RB" } do
		local q = quads[key]
		if not q then
			return nil
		end
		table.insert(out, Vector3.new(q.Sum.X / q.N, q.Sum.Y / q.N, q.Sum.Z / q.N))
		out[key] = q.R
		out[key .. "Parts"] = q.Parts
	end
	return out
end

-- Hacia dónde mira el morro (eje horizontal: ±X o ±Z), en el espacio del pack
local AXES = { ["-Z"] = Vector3.new(0, 0, -1), ["+Z"] = Vector3.new(0, 0, 1), ["-X"] = Vector3.new(-1, 0, 0), ["+X"] = Vector3.new(1, 0, 0) }
local function snapAxis(v: Vector3): Vector3
	if math.abs(v.X) > math.abs(v.Z) then
		return Vector3.new(if v.X > 0 then 1 else -1, 0, 0)
	end
	return Vector3.new(0, 0, if v.Z > 0 then 1 else -1)
end

local function forwardOf(shell: { BasePart }, wheels: { BasePart }, seat: BasePart?, front: string?, mode: string?): (Vector3, string)
	if front and AXES[front] then
		return AXES[front], "config"
	end
	if seat then
		return snapAxis(seat.CFrame.LookVector), "asiento"
	end
	local lo, hi = bounds(shell)
	local size = hi - lo
	local along = if size.X > size.Z then Vector3.new(1, 0, 0) else Vector3.new(0, 0, 1)
	if mode == "cab" and #shell >= 2 then
		-- Camión: la caja es la pieza más grande; la cabina (lo demás que no es cristal) va delante
		local box, vol = nil, 0
		for _, p in shell do
			local v = p.Size.X * p.Size.Y * p.Size.Z
			if v > vol then
				box, vol = p, v
			end
		end
		local sum, n = Vector3.zero, 0
		for _, p in shell do
			if p ~= box and not (p.Material == Enum.Material.Glass or p.Transparency > 0.1) then
				sum += p.CFrame.Position
				n += 1
			end
		end
		if box and n > 0 then
			local d = (sum / n - box.CFrame.Position):Dot(along)
			if math.abs(d) > 0.5 then
				return if d > 0 then along else -along, "cabina"
			end
		end
	end
	-- Voladizo: el de delante suele ser más largo que el de detrás
	local frame = CFrame.new()
	local centers = wheelCenters(wheels, frame)
	if centers then
		local a0, a1 = math.huge, -math.huge
		for i = 1, 4 do
			local v = centers[i]:Dot(along)
			a0, a1 = math.min(a0, v), math.max(a1, v)
		end
		local minA, maxA = lo:Dot(along), hi:Dot(along)
		local overNeg, overPos = a0 - minA, maxA - a1
		if mode == "bus" then
			-- autocar: el motor va detrás, el voladizo de atrás es el más largo
			return if overNeg <= overPos then -along else along, "voladizo"
		end
		return if overNeg >= overPos then -along else along, "voladizo"
	end
	return -along, "por defecto"
end

---------------------------------------------------------------------
-- Plantilla: copia limpia, girada, escalada y medida
---------------------------------------------------------------------
-- Escala de una pieza girada (en sus ejes) para una escala del modelo (sx, sy, sz)
local function localScale(cf: CFrame, s: Vector3): Vector3
	local function along(a: Vector3): number
		return math.sqrt((a.X * s.X) ^ 2 + (a.Y * s.Y) ^ 2 + (a.Z * s.Z) ^ 2)
	end
	return Vector3.new(along(cf.RightVector), along(cf.UpVector), along(cf.LookVector))
end

local function isGlass(p: BasePart): boolean
	return p.Material == Enum.Material.Glass or (p.Transparency > 0.1 and p.Transparency < 0.98) or string.find(lower(p.Name), "glass", 1, true) ~= nil or string.find(lower(p.Name), "window", 1, true) ~= nil
end

local function textured(p: BasePart): boolean
	if p:IsA("MeshPart") then
		local ok, id = pcall(function()
			return (p :: MeshPart).TextureID
		end)
		if ok and type(id) == "string" and id ~= "" then
			return true
		end
	end
	return p:FindFirstChildWhichIsA("SurfaceAppearance") ~= nil
end

local function colorKey(c: Color3): string
	return string.format("%d_%d_%d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

-- Qué piezas son la pintura: por nombre (Paint/Body/Color), por diferencia con otra versión de color
-- del mismo coche, o el grupo de color con más superficie (que no sea cristal, negro, gris ni cromo)
local function paintParts(shell: { BasePart }, other: { BasePart }?): { [BasePart]: boolean }
	local out = {}
	local any = false
	for _, p in shell do
		local n = lower(p.Name)
		if not isGlass(p) and not textured(p) and (string.find(n, "paint", 1, true) or string.find(n, "color", 1, true) or string.find(n, "colour", 1, true)) then
			out[p] = true
			any = true
		end
	end
	if any then
		return out
	end
	if other and #other == #shell then
		for i, p in shell do
			local q = other[i]
			if q.Name == p.Name and colorKey(q.Color) ~= colorKey(p.Color) and not isGlass(p) and not textured(p) then
				out[p] = true
				any = true
			end
		end
		if any then
			return out
		end
	end
	local area: { [string]: number } = {}
	for _, p in shell do
		if isGlass(p) or textured(p) or p.Material == Enum.Material.Neon then
			continue
		end
		local c = p.Color
		local h, sat, v = c:ToHSV()
		local _ = h
		if v < 0.18 or (sat < 0.12 and v < 0.75 and v > 0.3) then
			continue -- negro, gris o cromo (gomas, plásticos, molduras)
		end
		local s = p.Size
		area[colorKey(c)] = (area[colorKey(c)] or 0) + s.X * s.Y + s.Y * s.Z + s.X * s.Z
	end
	local best, bestA = nil, 0
	for k, a in area do
		if a > bestA then
			best, bestA = k, a
		end
	end
	if best then
		for _, p in shell do
			if colorKey(p.Color) == best and not isGlass(p) and not textured(p) and p.Material ~= Enum.Material.Neon then
				out[p] = true
			end
		end
	end
	return out
end

-- ¿Es un logo? (por su nombre o porque su imagen es uno de los logos vistos en los docs)
function CarBodies.isLogo(d: Decal): boolean
	if hasWord(d.Name, LOGO_WORDS) or CarBodies.isBrand(d.Name) then
		return true
	end
	local id = tonumber(string.match(tostring(d.Texture), "(%d+)%D*$") or "")
	return id ~= nil and CarBodies.LogoIds[id] == true
end

-- Copia limpia de una pieza: sin hijos (salvo su aspecto: SurfaceAppearance o la malla), sin atributos
local function cleanClone(p: BasePart, noDecals: boolean?): BasePart?
	local ok, clone = pcall(function()
		return p:Clone()
	end)
	if not ok or not clone then
		return nil
	end
	for _, c in clone:GetDescendants() do
		if c.Parent == clone and (c:IsA("SurfaceAppearance") or c:IsA("DataModelMesh")) then
			continue
		end
		if c.Parent == clone and not noDecals and (c:IsA("Decal") or c:IsA("Texture")) and not CarBodies.isLogo(c :: any) then
			c.Name = if c:IsA("Texture") then "CarTexture" else "CarDecal"
			continue
		end
		if c.Parent then
			c:Destroy()
		end
	end
	for name in clone:GetAttributes() do
		clone:SetAttribute(name, nil)
	end
	for _, tag in clone:GetTags() do
		clone:RemoveTag(tag)
	end
	return clone
end

local function badge(parent: Instance, name: string, cf: CFrame, brand: string, face: Enum.NormalId)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(1.1, 0.32, 0.06)
	p.CFrame = cf
	p.Color = Color3.fromRGB(205, 208, 214)
	p.Material = Enum.Material.Metal
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 1
	gui.Parent = p
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(30, 32, 36)
	label.TextScaled = true
	label.Text = brand
	label.Parent = gui
	p.Parent = parent
end

-- Mide la malla con rayos (morro, cola, costado, techo). Sin workspace (Lune) usa la caja.
local function calibrate(model: Model, lo: Vector3, hi: Vector3)
	local m = {
		FrontLampZ = lo.Z + 0.3,
		FrontMidZ = lo.Z + 0.1,
		RearLampZ = hi.Z - 0.3,
		RearMidZ = hi.Z - 0.1,
		SideX = hi.X - 0.15,
		RoofY = hi.Y,
	}
	pcall(function()
		local ws = workspace
		if typeof(ws) ~= "Instance" then
			return -- (Lune: sin rayos, se usa la caja)
		end
		local far = CFrame.new(0, 4000, 30000)
		local parts = {}
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") and p.Name ~= "CarBadge" then
				p.CFrame = far * p.CFrame
				p.CanQuery = true
				table.insert(parts, p)
			end
		end
		model.Parent = ws
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = parts
		local function cast(from: Vector3, dir: Vector3): Vector3?
			local r = ws:Raycast(far * from, far:VectorToWorldSpace(dir), params)
			return if r then far:PointToObjectSpace(r.Position) else nil
		end
		local hx = (hi.X - lo.X) / 2
		local lampX = math.max(hx - 1.1, 0.5)
		local function front(x: number, y: number, z0: number, dir: number): number?
			local a = cast(Vector3.new(x, y, z0), Vector3.new(0, 0, dir * 60))
			local b = cast(Vector3.new(-x, y, z0), Vector3.new(0, 0, dir * 60))
			if a and b then
				return if dir > 0 then math.min(a.Z, b.Z) else math.max(a.Z, b.Z)
			end
			return if a then a.Z elseif b then b.Z else nil
		end
		m.FrontLampZ = front(lampX, 2.75, lo.Z - 30, 1) or m.FrontLampZ
		m.FrontMidZ = front(0, 1.6, lo.Z - 30, 1) or m.FrontMidZ
		m.RearLampZ = front(lampX, 2.8, hi.Z + 30, -1) or m.RearLampZ
		m.RearMidZ = front(0, 2.2, hi.Z + 30, -1) or m.RearMidZ
		local side = cast(Vector3.new(hi.X + 30, 2.6, 0), Vector3.new(-60, 0, 0))
		if side then
			m.SideX = side.X
		end
		local top = cast(Vector3.new(0, hi.Y + 30, 0.6), Vector3.new(0, -60, 0))
		if top then
			m.RoofY = top.Y
		end
		model.Parent = nil
		for _, p in parts do
			p.CFrame = far:Inverse() * p.CFrame
			p.CanQuery = false
		end
	end)
	model.Parent = nil
	for k, v in m do
		model:SetAttribute(k, v)
	end
	-- (si un rayo dio en otra cosa: las piezas vuelven a su sitio igual)
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			if p.CFrame.Position.Magnitude > 20000 then
				p.CFrame = CFrame.new(0, -4000, -30000) * p.CFrame
			end
			p.CanQuery = false
		end
	end
end

-- Aspecto de una pieza de la malla según su zona (solo si no trae textura ni PBR: esas se quedan)
function CarBodies.finishLook(part: BasePart, zone: string?)
	if textured(part) then
		return
	end
	local look = CarBodies.Look
	if zone == "Primary" then
		part.Material = (Enum.Material :: any)[look.Paint.Material]
		part.Reflectance = look.Paint.Reflectance
	elseif zone == "Glass" then
		part.Color = look.Glass.Color
		part.Material = Enum.Material.Glass
		part.Transparency = look.Glass.Transparency
		part.Reflectance = look.Glass.Reflectance
	elseif part.Material ~= Enum.Material.Neon then
		local _, sat, v = part.Color:ToHSV()
		if sat < 0.15 and v > 0.7 then
			part.Material = (Enum.Material :: any)[look.Chrome.Material]
			part.Reflectance = look.Chrome.Reflectance
			part:SetAttribute("CarZone", "Chrome")
		end
	end
end

-- Neumáticos de malla: las piezas de la rueda delantera izquierda del pack, respecto a su centro y
-- a la talla de nuestras ruedas (radio 1,3). Van en la carpeta «Tire» de la plantilla.
local function tireTemplate(model: Model, wc: any, frame: CFrame)
	local group = wc and wc.LFParts
	local radius = wc and wc.LF
	if type(group) ~= "table" or type(radius) ~= "number" or radius <= 0.1 then
		return
	end
	local list = table.clone(group)
	table.sort(list, function(a, b)
		return a.Size.X * a.Size.Y * a.Size.Z > b.Size.X * b.Size.Y * b.Size.Z
	end)
	local hub = frame * CFrame.new(wc[1])
	local k = WHEEL_Y / radius
	local folder = Instance.new("Folder")
	folder.Name = "Tire"
	for i = 1, math.min(#list, CarBodies.TireParts) do
		local p = list[i]
		local clone = cleanClone(p)
		if clone then
			local rel = hub:Inverse() * p.CFrame
			local pos = rel.Position
			clone.Size = p.Size * k
			clone.CFrame = CFrame.new(pos * k) * (rel - pos)
			clone.Name = "TireMesh"
			clone:SetAttribute("CarMesh", true)
			clone.Anchored = true
			clone.CanCollide = false
			clone.CanQuery = false
			clone.CanTouch = false
			clone.Massless = true
			clone.CastShadow = false
			pcall(function()
				(clone :: any).RenderFidelity = Enum.RenderFidelity.Automatic
			end)
			clone.Parent = folder
		end
	end
	if #folder:GetChildren() > 0 then
		folder.Parent = model
	else
		folder:Destroy()
	end
end

-- Hace la plantilla de un coche del pack. pick = la entrada de Sources; other = otra versión de color
-- del mismo coche (para saber qué es pintura). Devuelve el Model (sin padre) o nil y por qué.
function CarBodies.template(car: Instance, pick: { [string]: any }, sourceId: number, other: Instance?): (Model?, string?)
	local shell, wheels, seat = carParts(car, pick.KeepWheels)
	if #shell == 0 then
		return nil, "sin carrocería"
	end
	-- Las N piezas más grandes (las demás son tornillos, pegatinas…)
	if pick.MaxParts and #shell > pick.MaxParts then
		table.sort(shell, function(a, b)
			return a.Size.X * a.Size.Y * a.Size.Z > b.Size.X * b.Size.Y * b.Size.Z
		end)
		for i = #shell, pick.MaxParts + 1, -1 do
			table.remove(shell, i)
		end
	end
	local otherShell = if other then (carParts(other)) else nil
	local paint = paintParts(shell, otherShell)

	-- Giro: el morro a −Z
	local fwd, why = forwardOf(shell, wheels, seat, pick.Front, pick.FrontBy)
	local yaw = CFrame.Angles(0, math.atan2(-fwd.X, -fwd.Z), 0) -- su LookVector = fwd
	local lo0, hi0 = bounds(shell, yaw)
	local center0 = (lo0 + hi0) / 2
	local frame = yaw * CFrame.new(center0.X, 0, center0.Z) -- espacio «girado y centrado»
	local lo, hi = bounds(shell, frame)
	local wc = wheelCenters(wheels, frame)
	local typ = CarBodies.Types[pick.Type] or CarBodies.Types.Sedan
	local L, W = hi.Z - lo.Z, hi.X - lo.X

	-- Escala: los pasos de rueda sobre nuestras ruedas (si el largo sale razonable), ancho 6,2 y
	-- techo a la altura del tipo
	local ground, zc, xc = lo.Y - 0.06 * (hi.Y - lo.Y), (lo.Z + hi.Z) / 2, (lo.X + hi.X) / 2
	local sz = typ.Length / L
	if wc then
		local frontZ = (wc[1].Z + wc[2].Z) / 2
		local rearZ = (wc[3].Z + wc[4].Z) / 2
		local radius = ((wc :: any).LF + (wc :: any).RB) / 2
		local wb = rearZ - frontZ
		local avgY = (wc[1].Y + wc[2].Y + wc[3].Y + wc[4].Y) / 4
		ground = avgY - radius
		if wb > 0.1 then
			local s = 2 * WHEEL_Z / wb
			if L * s >= typ.Length * 0.85 and L * s <= typ.Length * 1.18 then
				sz = s
				zc = (frontZ + rearZ) / 2
			end
		end
		xc = (wc[1].X + wc[2].X + wc[3].X + wc[4].X) / 4
	end
	local sx = math.clamp((typ.Width or CAR_W) / W, sz * 0.8, sz * 1.25)
	local height = math.max(hi.Y - ground, 0.5)
	local sy = math.clamp(typ.Roof / height, (sx + sz) / 2 * 0.85, (sx + sz) / 2 * 1.35)
	local scale = Vector3.new(sx, sy, sz)
	local origin = frame * CFrame.new(xc, ground, zc)

	local model = Instance.new("Model")
	model.Name = pick.Name
	local tris = pick.Tris or 0
	local kept = 0
	for _, p in shell do
		local clone = cleanClone(p, pick.NoDecals)
		if not clone then
			continue
		end
		local rel = origin:Inverse() * p.CFrame
		local pos = rel.Position
		local rot = rel - pos
		local ls = localScale(rel, scale)
		clone.Size = Vector3.new(p.Size.X * ls.X, p.Size.Y * ls.Y, p.Size.Z * ls.Z)
		clone.CFrame = CFrame.new(pos.X * sx, pos.Y * sy, pos.Z * sz) * rot
		for _, mesh in clone:GetChildren() do
			if mesh:IsA("SpecialMesh") or mesh:IsA("BlockMesh") or mesh:IsA("CylinderMesh") then
				pcall(function()
					(mesh :: any).Scale = (mesh :: any).Scale * ls;
					(mesh :: any).Offset = (mesh :: any).Offset * ls
				end)
			end
		end
		local zone = if paint[p] then "Primary" elseif isGlass(p) then "Glass" else nil
		clone.Name = if zone == "Primary" then "CarShell" elseif zone == "Glass" then "CarGlass" else "CarTrim"
		CarBodies.finishLook(clone, zone)
		if zone then
			clone:SetAttribute("CarZone", zone)
		end
		clone:SetAttribute("CarMesh", true)
		clone.Anchored = true
		clone.CanCollide = false
		clone.CanQuery = false
		clone.CanTouch = false
		clone.Massless = true
		local big = math.max(clone.Size.X, clone.Size.Y, clone.Size.Z)
		clone.CastShadow = big >= CarBodies.ShadowSize and not (zone == "Glass")
		pcall(function()
			(clone :: any).RenderFidelity = Enum.RenderFidelity.Automatic
		end)
		clone.Parent = model
		kept += 1
	end
	if kept == 0 then
		return nil, "ninguna pieza se pudo copiar"
	end
	local flo, fhi = bounds(model:GetChildren() :: any)
	calibrate(model, flo, fhi)
	if not pick.Heavy then
		pcall(tireTemplate, model, wc, frame)
	end
	-- Placas con la marca inventada (tapan el sitio del logo de delante y de detrás)
	local fz, rz = model:GetAttribute("FrontMidZ") :: number, model:GetAttribute("RearMidZ") :: number
	badge(model, "CarBadge", CFrame.new(0, 2.45, fz - 0.03), pick.Brand or "VALMAR MOTORS", Enum.NormalId.Front)
	badge(model, "CarBadge", CFrame.new(0, 3.0, rz + 0.03), pick.Brand or "VALMAR MOTORS", Enum.NormalId.Back)
	model:SetAttribute("Type", pick.Type)
	model:SetAttribute("Brand", pick.Brand)
	model:SetAttribute("Source", sourceId)
	model:SetAttribute("Tris", tris)
	model:SetAttribute("Paintable", next(paint) ~= nil)
	model:SetAttribute("Roles", table.concat(pick.Roles or CIVIL, ","))
	model:SetAttribute("Weight", pick.Weight or 1)
	model:SetAttribute("MaxCopies", pick.MaxCopies or 0)
	model:SetAttribute("Hero", pick.Hero == true)
	model:SetAttribute("Heavy", pick.Heavy == true)
	model:SetAttribute("Forward", why)
	model:SetAttribute("Length", fhi.Z - flo.Z)
	model:SetAttribute("Width", fhi.X - flo.X)
	return model, nil
end

-- Rueda de malla suelta (WheelSources): sus piezas visibles, centradas, con el eje a lo largo de X y
-- del tamaño de nuestras ruedas (radio 1,3). Devuelve la carpeta «Tire» o nil.
function CarBodies.wheelFrom(pack: Instance, def: { [string]: any }): Folder?
	local list = {}
	for _, d in pack:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.98 and not CarBodies.isBrand(d.Name) then
			table.insert(list, d)
		end
	end
	if pack:IsA("BasePart") then
		table.insert(list, pack)
	end
	if #list == 0 then
		return nil
	end
	local lo, hi = bounds(list)
	local size = hi - lo
	local center = (lo + hi) / 2
	-- eje = el lado más corto de la caja
	local turn = CFrame.new()
	local diameter = math.max(size.Y, size.Z)
	if size.Y < size.X and size.Y <= size.Z then
		turn = CFrame.Angles(0, 0, math.pi / 2)
		diameter = math.max(size.X, size.Z)
	elseif size.Z < size.X and size.Z < size.Y then
		turn = CFrame.Angles(0, math.pi / 2, 0)
		diameter = math.max(size.X, size.Y)
	end
	local k = 2 * WHEEL_Y / math.max(diameter, 0.1)
	local folder = Instance.new("Folder")
	folder.Name = "Tire"
	table.sort(list, function(a, b)
		return a.Size.X * a.Size.Y * a.Size.Z > b.Size.X * b.Size.Y * b.Size.Z
	end)
	for i = 1, math.min(#list, CarBodies.TireParts) do
		local p = list[i]
		local clone = cleanClone(p, true)
		if clone then
			local rel = turn * (CFrame.new(center):Inverse() * p.CFrame)
			local pos = rel.Position
			clone.Size = p.Size * k
			clone.CFrame = CFrame.new(pos * k) * (rel - pos)
			clone.Name = "TireMesh"
			clone:SetAttribute("CarMesh", true)
			clone.Anchored = true
			clone.CanCollide = false
			clone.CanQuery = false
			clone.CanTouch = false
			clone.Massless = true
			clone.CastShadow = false
			pcall(function()
				(clone :: any).RenderFidelity = Enum.RenderFidelity.Automatic
			end)
			clone.Parent = folder
		end
	end
	if #folder:GetChildren() == 0 then
		return nil
	end
	folder:SetAttribute("KeepRim", def.KeepRim == true)
	folder:SetAttribute("Source", def.Id)
	folder:SetAttribute("Tris", def.Tris)
	return folder
end

-- Hace las plantillas de un pack ya cargado (según su entrada de Sources). Devuelve cuántas.
function CarBodies.ingest(def: { [string]: any }, pack: Instance): number
	local cars = CarBodies.findCars(pack)
	local used: { [Instance]: boolean } = {}
	local n = 0
	for _, pick in def.Picks do
		local chosen, other = nil, nil
		for _, car in cars do
			if not used[car] and (pick.Match == "" or string.find(lower(car.Name), pick.Match, 1, true)) then
				if not chosen then
					chosen = car
				elseif not other then
					other = car
				end
			end
		end
		if not chosen then
			continue
		end
		used[chosen] = true
		if pick.Match ~= "" and other then
			other = nil -- (con nombre: solo ese coche; las versiones de color son de los oficiales)
		end
		local cap = if pick.Heavy then CarBodies.MaxHeavyTris else CarBodies.MaxTris
		if pick.Hero ~= true and (pick.Tris or 0) > cap then
			continue
		end
		local ok, model, why = pcall(CarBodies.template, chosen, pick, def.Id, other)
		if ok and model then
			table.insert(library, model)
			n += 1
		else
			warn(("[CarBodies] %s (%d): %s"):format(pick.Name, def.Id, tostring(if ok then why else model)))
		end
	end
	return n
end

---------------------------------------------------------------------
-- Elegir y poner
---------------------------------------------------------------------
local function hasRole(t: Model, role: string): boolean
	local roles = t:GetAttribute("Roles")
	return type(roles) == "string" and table.find(string.split(roles, ","), role) ~= nil
end

-- Carrocería para un papel y una clave (determinista). types: lista de tipos que valen (o nil).
function CarBodies.choose(role: string, key: any, types: { string }?): Model?
	local list, total = {}, 0
	for _, t in library do
		if not hasRole(t, role) then
			continue
		end
		if types and not table.find(types, t:GetAttribute("Type")) then
			continue
		end
		if role == "Player" and t:GetAttribute("Paintable") ~= true then
			continue
		end
		local max = t:GetAttribute("MaxCopies")
		if type(max) == "number" and max > 0 and (copies[t.Name] or 0) >= max then
			continue
		end
		local w = t:GetAttribute("Weight")
		w = if type(w) == "number" and w > 0 then w else 1
		table.insert(list, { T = t, W = w })
		total += w
	end
	if #list == 0 then
		if types then
			return CarBodies.choose(role, key, nil)
		end
		return nil
	end
	table.sort(list, function(a, b)
		return a.T.Name < b.T.Name
	end)
	local r = (CarBodies.hash(key) % 100000) / 100000 * total
	for _, e in list do
		r -= e.W
		if r < 0 then
			return e.T
		end
	end
	return list[#list].T
end

function CarBodies.find(name: string): Model?
	for _, t in library do
		if t.Name == name then
			return t
		end
	end
	return nil
end

-- MaterialVariant de pintura de coche (Modern City Materials Pack, lo pone World/Buildings3D en
-- MaterialService con su prefijo). Se busca de vez en cuando hasta que aparezca.
local paintVariant: string? = nil
local paintBase: Enum.Material? = nil
local paintLookedAt = -math.huge
function carPaintVariant(): string?
	if paintVariant then
		return paintVariant
	end
	local now = os.clock()
	if now - paintLookedAt < 20 then
		return nil
	end
	paintLookedAt = now
	pcall(function()
		for _, v in game:GetService("MaterialService"):GetDescendants() do
			if v:IsA("MaterialVariant") and string.find(string.lower(v.Name), "carpaint", 1, true) then
				paintVariant = v.Name
				paintBase = (v :: any).BaseMaterial
				return
			end
		end
	end)
	return paintVariant
end

-- Dónde está el coche (centro a ras de suelo): por su base si ya está preparado (Rides.prepare)
local function groundOf(model: Model, cf: CFrame): CFrame
	local chassis = model:FindFirstChild("Chassis")
	if chassis and chassis:IsA("BasePart") then
		return chassis.CFrame * CFrame.new(0, -chassis.Size.Y / 2, 0)
	end
	return cf
end

local function setZ(part: BasePart, base: CFrame, z: number, sideX: number)
	local rel = base:Inverse() * part.CFrame
	local p = rel.Position
	local x = math.clamp(p.X, -(sideX - 0.4), sideX - 0.4)
	part.CFrame = base * CFrame.new(x, p.Y, z) * (rel - p)
end

--[[ Cambia la carrocería de piezas de un coche (CarModel; también la patrulla y el taxi) por una
malla. opts: Role ("Parked" | "Traffic" | "Player" | "Policia" | "Taxi"), Key (elección determinista),
Variant (Berlina / Compacto / Todoterreno), Template (nombre de una plantilla concreta).
Devuelve true si la ha cambiado. Sin plantillas todavía (cargando) la deja apuntada para luego. ]]
function CarBodies.dress(model: Model, cf: CFrame, opts: { [string]: any }?): boolean
	local o = opts or {}
	if CarBodies.State == "loading" or CarBodies.State == "idle" then
		-- (aún no hay plantillas: se apunta; si la carga falla, se olvida y el coche se queda igual)
		table.insert(pending, { Model = model, Cf = cf, Opts = o })
		return false
	end
	if not CarBodies.ready() then
		return false
	end
	for _, c in model:GetChildren() do
		if c:GetAttribute("CarMesh") then
			return true -- (ya la tiene)
		end
	end
	local role = o.Role or "Parked"
	if role == "Parked" and parkedCount >= CarBodies.MaxParked then
		return false
	end
	local variant = o.Variant or model:GetAttribute("Variant") or "Berlina"
	local template = if o.Template then CarBodies.find(o.Template) else nil
	if not template then
		local types = if role == "Player" or role == "Taxi" then CarBodies.VariantTypes[variant] else nil
		template = CarBodies.choose(role, o.Key or model.Name, types)
	end
	if not template then
		return false
	end
	local base = groundOf(model, cf)
	local chassis = model:FindFirstChild("Chassis") :: BasePart?
	local bodyPart = model:FindFirstChild("Body")
	local paint = if bodyPart and bodyPart:IsA("BasePart") then bodyPart.Color else model:GetAttribute("Paint")
	if role == "Parked" or role == "Traffic" then
		-- colores de coche de verdad (determinista por la clave)
		paint = CarBodies.Paints[CarBodies.hash("pintura" .. tostring(o.Key or model.Name)) % #CarBodies.Paints + 1]
		if bodyPart and bodyPart:IsA("BasePart") then
			bodyPart.Color = paint
		end
		model:SetAttribute("Paint", paint)
	end
	local variantName = carPaintVariant()
	local frontLamp, frontMid = template:GetAttribute("FrontLampZ") :: number, template:GetAttribute("FrontMidZ") :: number
	local rearLamp, rearMid = template:GetAttribute("RearLampZ") :: number, template:GetAttribute("RearMidZ") :: number
	local sideX, roofY = template:GetAttribute("SideX") :: number, template:GetAttribute("RoofY") :: number
	local boxRoof = BOX_ROOF[variant] or BOX_ROOF.Berlina

	-- 1. Nuestras piezas: se quedan, se mueven a la malla, se esconden (las que chocan) o se quitan
	for _, part in model:GetChildren() do
		if not part:IsA("BasePart") or part:IsA("Seat") or part:IsA("VehicleSeat") then
			continue
		end
		local name = part.Name
		if KEEP[name] or string.sub(name, 1, 4) == "Mod_" then
			continue
		elseif FRONT[name] then
			setZ(part, base, (if FRONT[name] == "Lamp" then frontLamp else frontMid) - 0.02 + part.Size.Z * 0.25, sideX)
		elseif REAR[name] then
			setZ(part, base, (if REAR[name] == "Lamp" then rearLamp else rearMid) + 0.02 - part.Size.Z * 0.25, sideX)
		elseif SIDE[name] then
			local rel = base:Inverse() * part.CFrame
			local p = rel.Position
			local sx = if p.X >= 0 then 1 else -1
			part.CFrame = base * CFrame.new(sx * (sideX + 0.04), p.Y - (boxRoof - roofY) * 0.25, p.Z) * (rel - p)
		elseif ROOF[name] then
			part.CFrame = base * CFrame.new(0, roofY - boxRoof, 0) * (base:Inverse() * part.CFrame)
		elseif part.CanCollide then
			-- caja de choque de siempre: invisible, mismo nombre y misma colisión
			part.Transparency = 1
			part.CastShadow = false
			part:SetAttribute("CarHidden", true)
			if part:GetAttribute("ModOrigTransparency") ~= nil then
				part:SetAttribute("ModOrigTransparency", 1)
			end
			for _, d in part:GetChildren() do
				if d:IsA("SurfaceGui") or d:IsA("Decal") then
					d.Enabled = false
				end
			end
		else
			part:Destroy()
		end
	end

	-- 2. La malla, en su sitio (soldada si el coche ya está preparado)
	for _, src in template:GetChildren() do
		if not src:IsA("BasePart") then
			continue
		end
		local p = src:Clone()
		p.CFrame = base * src.CFrame
		if typeof(paint) == "Color3" and p:GetAttribute("CarZone") == "Primary" then
			p.Color = paint
			if variantName and not textured(p) then
				pcall(function()
					if paintBase then
						p.Material = paintBase
					end
					(p :: any).MaterialVariant = variantName
					p.Reflectance = CarBodies.Look.Paint.VariantReflectance
				end)
			end
			local sa = p:FindFirstChildWhichIsA("SurfaceAppearance")
			if sa then
				pcall(function()
					(sa :: any).Color = paint
				end)
			end
		end
		if chassis then
			p.Anchored = false
			p:SetAttribute("Collide", false)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = chassis
			weld.Part1 = p
			weld.Parent = p
		end
		p.Parent = model
	end
	-- 3. Neumáticos de malla del pack en nuestras ruedas (giran con ellas: WheelRig «TireMesh»);
	-- nuestras ruedas de cilindro se quedan invisibles (las usa WheelRig para saber dónde están)
	local tire = template:FindFirstChild("Tire")
	local keepRim = false
	if wheelTemplate and CarBodies.WheelRoles[role] then
		tire = wheelTemplate
		keepRim = wheelTemplate:GetAttribute("KeepRim") == true
	end
	if tire and #tire:GetChildren() > 0 then
		for _, w in model:GetChildren() do
			if w.Name ~= "Wheel" or not w:IsA("BasePart") then
				continue
			end
			local right = (base:Inverse() * w.CFrame).Position.X > 0
			local hub = w.CFrame * (if right then CFrame.Angles(0, math.pi, 0) else CFrame.new())
			for _, src in tire:GetChildren() do
				if src:IsA("BasePart") then
					local t = src:Clone()
					t.CFrame = hub * src.CFrame
					if chassis then
						t.Anchored = false
						t:SetAttribute("Collide", false)
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = chassis
						weld.Part1 = t
						weld.Parent = t
					end
					t.Parent = model
				end
			end
		end
		for _, w in model:GetChildren() do
			if w:IsA("BasePart") and (w.Name == "Wheel" or (not keepRim and (w.Name == "Rim" or w.Name == "Spoke" or w.Name == "Hub"))) then
				w.Transparency = 1
				w:SetAttribute("CarHidden", true)
				if w:GetAttribute("ModOrigTransparency") ~= nil then
					w:SetAttribute("ModOrigTransparency", 1)
				end
			end
		end
	end
	model:SetAttribute("CarBody", template.Name)
	model:SetAttribute("CarBodySource", template:GetAttribute("Source"))
	copies[template.Name] = (copies[template.Name] or 0) + 1
	if role == "Parked" then
		parkedCount += 1
	end
	return true
end

---------------------------------------------------------------------
-- Autobús urbano: la malla encima de NUESTRO autobús (Rides «Autobus»), que sigue funcionando igual:
-- puertas que se abren (BusDoor), asientos, barras, validadora, conductor y letreros de la línea
-- (llevados al morro, la cola y el costado de la malla). La caja de siempre choca, invisible.
---------------------------------------------------------------------
local BUS_KEEP = {
	Floor = true, Ceiling = true, CeilingLight = true, GrabRail = true, Pole = true, StopButton = true,
	SeatBack = true, SeatFrame = true, Handle = true, WheelchairArea = true, WheelchairSign = true,
	ValidatorPost = true, Validator = true, ValidatorScreen = true, InfoScreen = true, DriverPartition = true,
	Dashboard = true, DashScreen = true, SteeringWheel = true, SteeringColumn = true, DriverSeatBack = true,
	DriverSeatBase = true, DoorFrame = true, DoorSeal = true, DoorStep = true, DoorStepEdge = true,
	DoorLight = true, BusDoor = true, Frame = true, Chassis = true,
}
local BUS_FRONT = { DestinationSign = true, SignGlow = true, Logo = true, Headlight = true, HeadlightSmall = true, LedStrip = true }
local BUS_REAR = { RearSign = true, Taillight = true, Reverse = true }
local BUS_SIDE = { SideSign = true, Advert = true }

function CarBodies.dressBus(model: Model, cf: CFrame, opts: { [string]: any }?): boolean
	if CarBodies.State == "loading" or CarBodies.State == "idle" then
		table.insert(pending, { Model = model, Cf = cf, Opts = opts or {}, Fn = CarBodies.dressBus })
		return false
	end
	if not CarBodies.ready() or model:GetAttribute("CarBody") then
		return false
	end
	local template = CarBodies.choose("Bus", model.Name)
	if not template then
		return false
	end
	local base = groundOf(model, cf)
	local chassis = model:FindFirstChild("Chassis") :: BasePart?
	local frontMid, rearMid = template:GetAttribute("FrontMidZ") :: number, template:GetAttribute("RearMidZ") :: number
	local sideX = template:GetAttribute("SideX") :: number
	for _, part in model:GetChildren() do
		if not part:IsA("BasePart") or part:IsA("Seat") or part:IsA("VehicleSeat") then
			continue
		end
		local name = part.Name
		local rel = base:Inverse() * part.CFrame
		local p = rel.Position
		local front = BUS_FRONT[name] or ((name == "Plate" or name == "Indicator") and p.Z < 0)
		local rear = BUS_REAR[name] or ((name == "Plate" or name == "Indicator") and p.Z > 0)
		if BUS_KEEP[name] then
			continue
		elseif front then
			part.CFrame = base * CFrame.new(p.X, p.Y, frontMid - 0.06) * (rel - p)
		elseif rear then
			part.CFrame = base * CFrame.new(p.X, p.Y, rearMid + 0.06) * (rel - p)
		elseif BUS_SIDE[name] then
			local sx = if p.X >= 0 then 1 else -1
			part.CFrame = base * CFrame.new(sx * (sideX + 0.05), p.Y, p.Z) * (rel - p)
		elseif part.CanCollide then
			part.Transparency = 1
			part.CastShadow = false
			part:SetAttribute("CarHidden", true)
			for _, d in part:GetChildren() do
				if d:IsA("SurfaceGui") or d:IsA("Decal") then
					d.Enabled = false
				end
			end
		else
			part:Destroy()
		end
	end
	for _, src in template:GetChildren() do
		if not src:IsA("BasePart") or src.Name == "CarBadge" then
			continue
		end
		local q = src:Clone()
		q.CFrame = base * src.CFrame
		if chassis then
			q.Anchored = false
			q:SetAttribute("Collide", false)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = chassis
			weld.Part1 = q
			weld.Parent = q
		end
		q.Parent = model
	end
	model:SetAttribute("CarBody", template.Name)
	model:SetAttribute("CarBodySource", template:GetAttribute("Source"))
	return true
end

---------------------------------------------------------------------
-- Pesados del tráfico (camión de reparto y autocar): un modelo nuevo con la malla, su caja de choque
-- invisible «Body» y nuestras luces (faros, pilotos, intermitentes) en el morro y la cola de la malla.
-- Centro a ras de suelo, morro a −Z (como las plantillas de Ambient.Cars).
---------------------------------------------------------------------
function CarBodies.heavy(template: Model, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	for _, src in template:GetChildren() do
		if src:IsA("BasePart") then
			src:Clone().Parent = m
		end
	end
	local typ = CarBodies.Types[template:GetAttribute("Type")] or CarBodies.Types.Reparto
	local length, width = template:GetAttribute("Length") :: number, template:GetAttribute("Width") :: number
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(width - 0.4, typ.Roof - 1.2, length - 0.4)
	body.CFrame = CFrame.new(0, 0.9 + (typ.Roof - 1.2) / 2, 0)
	body.Transparency = 1
	body.Anchored = true
	body.CanCollide = true
	body.CastShadow = false
	body:SetAttribute("CarHidden", true)
	body.Parent = m
	local fz, rz = template:GetAttribute("FrontLampZ") :: number, template:GetAttribute("RearLampZ") :: number
	local hx = math.max(width / 2 - 1, 1)
	local function lamp(n: string, x: number, y: number, z: number, color: Color3, size: Vector3)
		local l = Instance.new("Part")
		l.Name = n
		l.Size = size
		l.CFrame = CFrame.new(x, y, z)
		l.Color = color
		l.Material = Enum.Material.Neon
		l.Anchored = true
		l.CanCollide = false
		l.CanQuery = false
		l.CanTouch = false
		l.CastShadow = false
		l.Parent = m
	end
	for _, sx in { -1, 1 } do
		lamp(if sx < 0 then "Headlight" else "HeadlightRight", sx * hx, 2.6, fz + 0.1, Color3.fromRGB(255, 250, 235), Vector3.new(1, 0.45, 0.25))
		lamp("IndicatorFront", sx * (hx + 0.6), 2.6, fz + 0.1, Color3.fromRGB(255, 150, 20), Vector3.new(0.35, 0.3, 0.2))
		lamp("Taillight", sx * hx, 2.6, rz - 0.1, Color3.fromRGB(200, 20, 30), Vector3.new(1, 0.5, 0.25))
		lamp("IndicatorRear", sx * (hx + 0.6), 2.6, rz - 0.1, Color3.fromRGB(255, 150, 20), Vector3.new(0.35, 0.3, 0.2))
	end
	m:SetAttribute("Kind", "Pesado")
	m:SetAttribute("CarBody", template.Name)
	m:SetAttribute("Length", length)
	return m
end

---------------------------------------------------------------------
-- Carga en vivo
---------------------------------------------------------------------
local function download(id: number): Instance?
	local ok, result = pcall(function()
		return (game:GetService("AssetService") :: any):LoadAssetAsync(id)
	end)
	if ok and result then
		return result
	end
	ok, result = pcall(function()
		return game:GetService("InsertService"):LoadAsset(id)
	end)
	if ok and result then
		return result
	end
	warn(("[CarBodies] no carga %d: %s"):format(id, tostring(result)))
	return nil
end
CarBodies.download = download

-- Cambia los coches apuntados mientras se cargaba, en tandas
local function flush()
	local list = pending
	pending = {}
	for i, item in list do
		if item.Model.Parent ~= nil then
			local ok, err = pcall(item.Fn or CarBodies.dress, item.Model, item.Cf, item.Opts)
			if not ok then
				warn("[CarBodies] " .. tostring(err))
			end
		end
		if i % CarBodies.Batch == 0 then
			task.wait()
		end
	end
end

-- Termina la carga (también la usa la prueba con packs falsos): listo si hay alguna plantilla
function CarBodies.finish()
	if #library == 0 then
		CarBodies.State = "failed"
		pending = {}
		readyCallbacks = {}
		return
	end
	local store = Instance.new("Folder")
	store.Name = "CarBodies"
	for _, t in library do
		t:Clone().Parent = store
	end
	pcall(function()
		local old = game:GetService("ServerStorage"):FindFirstChild("CarBodies")
		if old then
			old:Destroy()
		end
		store.Parent = game:GetService("ServerStorage")
	end)
	CarBodies.State = "ready"
	local callbacks = readyCallbacks
	readyCallbacks = {}
	for _, fn in callbacks do
		local ok, err = pcall(fn)
		if not ok then
			warn("[CarBodies] " .. tostring(err))
		end
	end
	flush()
end

-- loader(id) -> Instance? (por defecto, la descarga de verdad)
function CarBodies.start(loader: ((number) -> Instance?)?)
	if CarBodies.State ~= "idle" then
		return
	end
	CarBodies.State = "loading"
	local load = loader or download
	for _, def in CarBodies.Sources do
		local pack = nil
		for _, id in { def.Id, table.unpack(def.Fallback or {}) } do
			local ok, result = pcall(load, id)
			if ok and result then
				pack = result
				break
			end
		end
		if pack then
			local ok, n = pcall(CarBodies.ingest, def, pack)
			if not ok then
				warn(("[CarBodies] %d: %s"):format(def.Id, tostring(n)))
			end
			pcall(function()
				pack:Destroy()
			end)
		end
	end
	for _, def in CarBodies.WheelSources do
		local ok, pack = pcall(load, def.Id)
		if ok and pack then
			local okW, folder = pcall(CarBodies.wheelFrom, pack, def)
			pcall(function()
				pack:Destroy()
			end)
			if okW and folder then
				wheelTemplate = folder
				break
			end
		end
	end
	local names = {}
	for _, t in library do
		table.insert(names, ("%s(%s)"):format(t.Name, tostring(t:GetAttribute("Forward"))))
	end
	print(("[CarBodies] %d carrocerías: %s"):format(#library, table.concat(names, ", ")))
	CarBodies.finish()
end

return CarBodies
