-- Prueba de la GASOLINA y los PINCHAZOS FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-tyres.luau
--
-- Comprueba:
--   * gasolina (shared/Gameplay): un depósito lleno dura una sesión larga (coche 45-60 min a 3/4 de
--     la velocidad máxima, moto más), repostar sigue contando, y los vehículos de pago gastan menos
--   * pinchazos (shared/Tyres): nombres de las ruedas, efectos (corre menos, agarra menos, tira hacia
--     el lado pinchado), disparo que atraviesa la rueda, choque fuerte (no siempre), mala suerte muy
--     rara, los de pago y el monopatín nunca
--   * el servidor (Services/TyreService, con modelos de verdad de Kit/Rides): pincha por disparo, por
--     choque y por mala suerte; repara en la gasolinera pagando; la rueda de repuesto solo para el
--     dueño, a pie, cerca y una vez; volver a sacarlo la arregla
--   * todo enganchado: VehicleService gasta con Gameplay.fuelUse y pone «Reparar rueda» en los
--     surtidores, WeaponService y CrashService avisan a TyreService, Driving y WheelSpin lo usan

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

local mods = {}
local baseEnv = { Instance = Instance, CFrame = CFrame, Vector3 = Vector3, Color3 = Color3, Enum = Enum, UDim2 = roblox.UDim2, UDim = roblox.UDim, Font = roblox.Font }
local function load(path: string, name: string, extra: { [string]: any }?)
	local env = setmetatable(table.clone(baseEnv), { __index = getfenv(1) })
	env.script = { Parent = { Parent = { Builder = "Builder" }, Palette = "Palette", CarModel = "CarModel" } }
	env.require = function(key)
		return mods[key] or error("módulo sin cargar: " .. tostring(key))
	end
	for k, v in extra or {} do
		env[k] = v
	end
	mods[name] = luau.load(fs.readFile(path), { debugName = path, environment = env })()
	return mods[name]
end
load("src/server/World/Builder.luau", "Builder")
load("src/server/World/Kit/Palette.luau", "Palette")
load("src/server/World/Kit/CarModel.luau", "CarModel")
local Rides = load("src/server/World/Kit/Rides.luau", "Rides")
local Gameplay = load("src/shared/Gameplay.luau", "Gameplay")
local Tyres = load("src/shared/Tyres.luau", "Tyres")

---------------------------------------------------------------------
print("Gasolina")
---------------------------------------------------------------------
do
	local car, moto, scooter = Gameplay.fuelMinutes("Coche"), Gameplay.fuelMinutes("Moto"), Gameplay.fuelMinutes("Patinete")
	check(car >= 45 and car <= 60, ("coche: un depósito dura %.0f min sin parar (a 3/4 de la máxima; antes 7)"):format(car))
	check(moto > car, ("moto: aún más (%.0f min)"):format(moto))
	check(scooter >= 45, ("patinete: la batería dura %.0f min"):format(scooter))
	local flatOut = Gameplay.fuelMinutes("Coche", Gameplay.Vehicles.Coche.Speed)
	check(flatOut >= 35, ("coche siempre a fondo: %.0f min (sigue habiendo que repostar)"):format(flatOut))
	check(Gameplay.fuelMinutes("Coche") < 120, "pero no es infinito: repostar sigue contando")
	check(Gameplay.fuelMinutes("Bici") == nil and Gameplay.fuelUse("Bici", 1000) == 0, "bici y monopatín no gastan")
	local normal, premium = Gameplay.fuelUse("Coche", 10000), Gameplay.fuelUse("Coche", 10000, true)
	check(premium > 0 and premium < normal, ("los de pago gastan menos (%.2f L frente a %.2f L cada 10.000 studs)"):format(premium, normal))
	check(math.abs(Gameplay.fuelMinutes("Coche", nil, true) / car - 1 / Gameplay.Fuel.PremiumFactor) < 1e-6, "y les dura el depósito en proporción")
	local spec = Gameplay.Fuel.Kinds.Coche
	check(spec.Tank * spec.Price >= 50, ("llenar el coche cuesta %d €: se nota"):format(spec.Tank * spec.Price))
end

---------------------------------------------------------------------
print("Pinchazos: las cuentas (shared/Tyres)")
---------------------------------------------------------------------
do
	local ids = Tyres.ids({ Vector3.new(-2.8, 1.3, -4.3), Vector3.new(2.8, 1.3, -4.3), Vector3.new(-2.8, 1.3, 4.3), Vector3.new(2.8, 1.3, 4.3) })
	check(ids[1] == "1L" and ids[2] == "1R" and ids[3] == "2L" and ids[4] == "2R", "coche: 1L 1R (delante) 2L 2R (detrás)")
	local truck = Tyres.ids({ Vector3.new(-3.3, 1.7, -9.5), Vector3.new(3.3, 1.7, 5.5), Vector3.new(-3.3, 1.7, 9) })
	check(truck[1] == "1L" and truck[2] == "2R" and truck[3] == "3L", "camión: tres ejes")
	local moto = Tyres.ids({ Vector3.new(0, 1, -2.3), Vector3.new(0, 1, 2.3) })
	check(moto[1] == "1" and moto[2] == "2", "moto: «1» y «2» (sin lado)")
	check(#Tyres.flats({ Flat_1L = true, Fuel = 3, Flat_2R = false }) == 1, "las pinchadas salen de los atributos Flat_… = true")
	local none = Tyres.effects({})
	check(none.MaxSpeed == 1 and none.Pull == 0 and none.Count == 0, "sin pinchazos: todo normal")
	local left = Tyres.effects({ "1L" })
	check(left.MaxSpeed < 1 and left.Traction < 1 and left.Turn < 1, "con una pinchada: corre, gira y agarra menos")
	check(left.Pull > 0 and Tyres.effects({ "2R" }).Pull < 0, "tira hacia el lado pinchado (izquierda +, derecha −)")
	check(Tyres.effects({ "1L", "1R" }).Pull == 0 and Tyres.effects({ "1L", "1R" }).MaxSpeed < left.MaxSpeed, "dos pinchadas: más lento (y una a cada lado no tira)")
	check(Tyres.effects({ "1" }).Pull == 0, "moto: no tira a ningún lado, pero va más lenta")
	-- Disparo: atraviesa la rueda (de lado) o pasa por encima
	local c, axis = Vector3.new(0, 1.3, 0), Vector3.new(1, 0, 0)
	check(Tyres.segmentHits(Vector3.new(-20, 1.3, 0.2), Vector3.new(20, 1.3, 0.2), c, axis, 1.3, 1.1), "un disparo que atraviesa la rueda la revienta")
	check(not Tyres.segmentHits(Vector3.new(-20, 4, 0), Vector3.new(20, 4, 0), c, axis, 1.3, 1.1), "uno que pasa por encima, no")
	check(not Tyres.segmentHits(Vector3.new(-20, 1.3, 0), Vector3.new(-5, 1.3, 0), c, axis, 1.3, 1.1), "uno que se para antes (en la carrocería), no")
	-- Choque: solo muy fuerte y no siempre
	check(not Tyres.crashPunctures(Tyres.CrashSpeed - 1, 0), "un golpe normal no pincha")
	check(Tyres.crashPunctures(Tyres.CrashSpeed + 5, 0.1) and not Tyres.crashPunctures(Tyres.CrashSpeed + 5, 0.9), "uno muy fuerte, a veces")
	-- Mala suerte: muy rara
	local hours = 1 / Tyres.RandomPer1000 * 1000 / (Gameplay.Vehicles.Coche.Speed * 0.75) / 3600
	check(hours >= 2, ("mala suerte: de media un pinchazo cada %.1f h de coche (nada de pinchazos constantes)"):format(hours))
	check(not Tyres.unlucky(0, 0) and not Tyres.unlucky(36, 0.5), "en medio segundo de viaje casi nunca")
	-- De pago
	check(Tyres.isPremium(nil, true) and Tyres.isPremium({ Premium = true }, nil) and not Tyres.isPremium(Gameplay.Vehicles.Coche, nil), "de pago: atributo Premium o Premium = true en su ficha")
	check(not Tyres.canPuncture("Coche", true), "los de pago no pinchan nunca")
	check(not Tyres.canPuncture("Monopatin", false) and not Tyres.canPuncture("Lancha", false), "el monopatín (ruedas macizas) y los barcos, tampoco")
	check(Tyres.canPuncture("Coche", false) and Tyres.canPuncture("Moto", false), "coches y motos normales, sí")
end

---------------------------------------------------------------------
print("Pinchazos: el servidor (Services/TyreService)")
---------------------------------------------------------------------
local notes: { { any } } = {}
local fakeNotify = { IsA = function(_, c)
	return c == "RemoteEvent"
end, FireClient = function(_, player, kind, text)
	table.insert(notes, { player, kind, text })
end }
local remotes = { FindFirstChild = function(_, name)
	return if name == "Notify" then fakeNotify else nil
end }
local playersById: { [number]: any } = {}
local world = Instance.new("Folder")
local ridesFolder = Instance.new("Folder")
ridesFolder.Name = "Rides"
ridesFolder.Parent = world
local fakeGame = {
	GetService = function(_, name)
		if name == "Players" then
			return { GetPlayerByUserId = function(_, id)
				return playersById[id]
			end }
		elseif name == "ReplicatedStorage" then
			return {
				Shared = { Gameplay = "Gameplay", Tyres = "Tyres" },
				FindFirstChild = function(_, n)
					return if n == "Remotes" then remotes else nil
				end,
			}
		end
		return {}
	end,
}
local TyreService = load("src/server/Services/TyreService.luau", "TyreService", { game = fakeGame, workspace = world })

local CF = CFrame.new(50, 0, 20)
local function vehicle(kind: string, owner: number?): any
	local model = Rides.build(kind, ridesFolder, CF)
	Rides.prepare(model, kind, CF)
	if owner then
		model:SetAttribute("OwnerId", owner)
	end
	return model
end
local function flatCount(model: any): number
	return #Tyres.flats(model:GetAttributes())
end
local function fakePlayer(id: number, seated: boolean, at: any)
	local root = { CFrame = CFrame.new(at), IsA = function(_, c)
		return c == "BasePart"
	end }
	local humanoid = { SeatPart = if seated then {} else nil }
	local character = {
		FindFirstChildOfClass = function(_, c)
			return if c == "Humanoid" then humanoid else nil
		end,
		FindFirstChild = function(_, n)
			return if n == "HumanoidRootPart" then root else nil
		end,
	}
	local p = { UserId = id, Character = character, Name = "J" .. id }
	playersById[id] = p
	return p
end

do
	local car = vehicle("Coche", 1)
	local wheels = TyreService.wheels(car)
	check(#wheels == 4, "el servidor encuentra las 4 ruedas del coche")
	-- Disparo de lado a la altura de la rueda delantera izquierda
	local fl
	for _, w in wheels do
		if w.Id == "1L" then
			fl = w
		end
	end
	local from = fl.Center + Vector3.new(-30, 0, 0)
	check(TyreService.shot(from, fl.Center + Vector3.new(-0.2, 0, 0)), "un disparo que llega a la rueda la revienta")
	check(car:GetAttribute("Flat_1L") == true and flatCount(car) == 1, "queda apuntado en el vehículo: Flat_1L (solo esa)")
	local spare = car.PrimaryPart:FindFirstChild("SparePrompt")
	check(spare ~= nil and spare.HoldDuration >= 3, "sale el cartel de la rueda de repuesto (mantener unos segundos)")
	check(not TyreService.shot(from + Vector3.new(0, 10, 0), fl.Center + Vector3.new(0, 10, 0)), "un disparo por encima no pincha nada")
	-- Rueda de repuesto: solo el dueño, a pie, cerca, una vez
	local center = car.PrimaryPart.CFrame.Position
	check(not TyreService.spare(fakePlayer(2, false, center), car), "otro jugador no puede cambiarla")
	check(not TyreService.spare(fakePlayer(1, true, center), car), "sentado dentro, no (hay que bajarse)")
	check(not TyreService.spare(fakePlayer(1, false, center + Vector3.new(60, 0, 0)), car), "lejos, no")
	check(TyreService.spare(fakePlayer(1, false, center + Vector3.new(3, 0, 0)), car) and flatCount(car) == 0, "el dueño, a pie y al lado: rueda cambiada")
	check(car.PrimaryPart:FindFirstChild("SparePrompt") == nil, "y el cartel se quita")
	TyreService.puncture(car, "2R", "Suerte")
	check(not TyreService.spare(fakePlayer(1, false, center), car) and flatCount(car) == 1, "la rueda de repuesto solo una vez cada vez que lo sacas")
	check(car.PrimaryPart:FindFirstChild("SparePrompt") == nil, "(ya sin cartel de repuesto)")
	-- Gasolinera: pagando
	local paid = 0
	check(not TyreService.repairAt(fakePlayer(1, true, center), car, function()
		return false
	end) and flatCount(car) == 1, "sin dinero no se repara")
	check(TyreService.repairAt(fakePlayer(1, true, center), car, function(cost)
		paid = cost
		return true
	end) and flatCount(car) == 0 and paid == Tyres.RepairPrice, ("en la gasolinera: reparada por %d €"):format(Tyres.RepairPrice))
	check(not TyreService.repairAt(fakePlayer(1, true, center), nil, function()
		return true
	end), "sin el vehículo al lado del surtidor, nada")
	-- Choque: muy fuerte, la rueda más cercana al golpe
	local rr
	for _, w in TyreService.wheels(car) do
		if w.Id == "2R" then
			rr = w
		end
	end
	check(not TyreService.crash(car, rr.Center, Tyres.CrashSpeed - 5, 0), "un golpe normal no pincha")
	check(TyreService.crash(car, rr.Center + Vector3.new(1, 0, 1), Tyres.CrashSpeed + 10, 0) and car:GetAttribute("Flat_2R") == true, "un golpe muy fuerte detrás a la derecha revienta la de detrás a la derecha")
	TyreService.repair(car)
	check(not TyreService.travelled(car, 30, 0.5) and flatCount(car) == 0, "mala suerte: en un trozo corto, casi nunca")
	check(TyreService.travelled(car, 1000, 0) and flatCount(car) == 1, "(si toca, pincha una rueda al azar)")
	-- Volver a sacarlo: modelo nuevo, sin pinchazos
	local again = vehicle("Coche", 1)
	check(flatCount(again) == 0 and again:GetAttribute("SpareUsed") == nil, "volver a sacarlo desde «Mis vehículos»: ruedas nuevas y rueda de repuesto")
end

do
	local premium = vehicle("Coche", 3)
	premium:SetAttribute("Premium", true)
	local w = TyreService.wheels(premium)[1]
	TyreService.shot(w.Center + Vector3.new(-30, 0, 0), w.Center) -- (los de antes, en el mismo sitio, sí pinchan)
	check(flatCount(premium) == 0, "de pago: un disparo no la pincha")
	check(not TyreService.crash(premium, w.Center, 90, 0) and not TyreService.travelled(premium, 1e6, 0) and flatCount(premium) == 0, "de pago: ni choques ni mala suerte")
	check(not TyreService.puncture(premium, "1L", "Disparo"), "de pago: ni aunque se pida directamente")
	local board = vehicle("Monopatin", 4)
	check(not TyreService.puncture(board, "1L", "Disparo"), "monopatín: ruedas macizas")
	local moto = vehicle("Moto", 5)
	check(TyreService.puncture(moto, "1", "Disparo") and #TyreService.wheels(moto) == 2, "la moto sí pincha (rueda «1», la de delante)")
end

---------------------------------------------------------------------
print("Todo enganchado (lectura del código)")
---------------------------------------------------------------------
local function read(path: string): string
	local ok, text = pcall(fs.readFile, path)
	return if ok then text else ""
end
local vehicleService = read("src/server/Services/VehicleService.luau")
local weaponService = read("src/server/Services/WeaponService.luau")
local crashService = read("src/server/Services/CrashService.luau")
local driving = read("src/client/Controllers/Driving.luau")
local wheelSpin = read("src/client/Controllers/WheelSpin.luau")
check(vehicleService:find("Gameplay.fuelUse(ride.Kind, d, TyreService.isPremium(ride.Model))", 1, true) ~= nil, "VehicleService gasta con Gameplay.fuelUse (los de pago, menos)")
check(vehicleService:find("TyreService.travelled", 1, true) ~= nil and vehicleService:find("\"TyrePrompt\"", 1, true) ~= nil and vehicleService:find("TyreService.repairAt", 1, true) ~= nil, "VehicleService: mala suerte en el viaje y «Reparar rueda» en los surtidores")
check(weaponService:find("TyreService.shot", 1, true) ~= nil and weaponService:find("w.Kind == \"Real\"", 1, true) ~= nil, "WeaponService: solo las balas de verdad revientan ruedas")
check(crashService:find("TyreService.crash", 1, true) ~= nil, "CrashService: los choques validados pueden pinchar")
check(driving:find("Tyres.effects", 1, true) ~= nil and driving:find("PinchazoFlap", 1, true) ~= nil, "Driving: con una pinchada corre menos, tira hacia su lado y suena el «flap»")
check(wheelSpin:find("Tyres.PREFIX", 1, true) ~= nil and wheelSpin:find("TyrePrompt", 1, true) ~= nil, "WheelSpin: la rueda pinchada se ve chafada y el surtidor ofrece repararla")
check(not driving:find("SetAttribute(\"Flat_", 1, true) and not wheelSpin:find("SetAttribute(Tyres.PREFIX", 1, true), "el cliente nunca pone ni quita pinchazos (solo el servidor)")

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
