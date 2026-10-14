-- Prueba de las piedras y lo que se rompe (shared/Breakables) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-breakables.luau                           # solo las reglas
--   lune run scripts/test-breakables.luau RealLifeSimulator.rbxl    # y además, el mapa construido
--
-- Comprueba que:
--   * se rompen las ventanas normales y los cristales de los coches, pero no las fachadas enteras
--     de cristal ni los escaparates de toda una manzana
--   * las puertas normales se pueden tirar (con muchas pedradas seguidas); los portones grandes, no
--   * las piedras se cogen de tierra, césped o arena, no del asfalto
--   * la piedra da donde apuntas (cerca, lejos, arriba, abajo); si está muy lejos, llega lo que puede
--   * en el mapa hay muchas ventanas y puertas que se pueden romper

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, Enum = roblox.Vector3, roblox.Enum
local env = setmetatable({ Vector3 = Vector3, Enum = Enum }, { __index = getfenv(1) })
local Breakables = luau.load(fs.readFile("src/shared/Breakables.luau"), { debugName = "Breakables", environment = env })()

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local GLASS, NEON = Enum.Material.Glass, Enum.Material.Neon
print("Qué se rompe")
check(Breakables.isGlass("WindowGlass", GLASS, Vector3.new(3.6, 4.4, 0.1)), "ventana de una casa")
check(Breakables.isGlass("Glass", NEON, Vector3.new(3.6, 7, 0.2)), "ventana encendida de noche (neón)")
check(Breakables.isGlass("Windshield", GLASS, Vector3.new(5.4, 0.1, 3.1)), "parabrisas de un coche")
check(not Breakables.isGlass("CurtainWall", GLASS, Vector3.new(38.8, 228, 0.6)), "la fachada de cristal de un rascacielos, no")
check(not Breakables.isGlass("Windows", GLASS, Vector3.new(116, 5.7, 0.3)), "la tira de ventanas de todo un bloque, no")
check(not Breakables.isGlass("ShopGlass", GLASS, Vector3.new(116, 6.5, 0.3)), "el escaparate de toda una manzana, no")
check(not Breakables.isGlass("WindowGlass", Enum.Material.Plastic, Vector3.new(3, 4, 0.1)), "si no es cristal, no")
check(not Breakables.isGlass("FridgeGlass", GLASS, Vector3.new(2, 4, 0.1)), "la puerta de la nevera del súper, no")
check(Breakables.glassKind("Glass", GLASS, Vector3.new(12, 10.3, 0.2)) == "Segmented", "el escaparate de una tienda se rompe (por tramos)")
check(Breakables.glassKind("Glass", GLASS, Vector3.new(6.4, 9.5, 0.2)) == "Segmented", "la puerta-ventana de un balcón grande, también")
check(Breakables.glassKind("ShopGlass", GLASS, Vector3.new(36, 6.5, 0.3)) == "Segmented" and Breakables.glassKind("Windows", GLASS, Vector3.new(86, 5.7, 0.3)) == "Segmented", "escaparates y franjas de ventanas de los bloques ligeros (Lite), por tramos")
check(Breakables.glassKind("ShopDoor", GLASS, Vector3.new(7.8, 9.8, 0.4)) == "Pane", "la puerta de cristal de una tienda se rompe entera")
check(Breakables.glassKind("CurtainWall", GLASS, Vector3.new(38.8, 228, 0.6)) == nil and Breakables.glassKind("FridgeGlass", GLASS, Vector3.new(2, 4, 0.1)) == nil, "las fachadas de cristal y las neveras, no")
local axis, n, width = Breakables.segmentLayout(Vector3.new(0.3, 5.7, 86))
check(axis == "Z" and n == math.ceil(86 / Breakables.SegmentWidth) and math.abs(width * n - 86) < 1e-6, "los tramos van a lo largo del cristal")
check(Breakables.segmentAt(-43, 86, n) == 1 and Breakables.segmentAt(43, 86, n) == n and #Breakables.segmentsAround(0, 3, 86, n) >= 1, "cada golpe cae en su tramo")
check(Breakables.repairDelay("Glass", 0) == 20 and Breakables.repairDelay("Glass", 1) == 30 and Breakables.repairDelay("Door", 0.5) > 30 and Breakables.repairDelay("Door", 1) == 45, "se arregla rápido: cristal 20–30 s, puertas 30–45 s")
check(Breakables.vandalCrime("Stone", 0, 1000) == "Danos" and Breakables.vandalCrime("Stone", 2, 1000) == nil and Breakables.vandalCrime("Bullet", 0, 1000) == nil, "«Daños» solo si nadie te buscaba (y no con balas)")
check(Breakables.isDoor("Door", Vector3.new(4, 7, 0.4)), "una puerta normal")
check(not Breakables.isDoor("DoorPanel", Vector3.new(8, 10, 0.3)), "un portón grande, no")
check(not Breakables.isDoor("GarageDoor", Vector3.new(10, 7.4, 0.2)), "la puerta del garaje, no")
check(Breakables.shards(Vector3.new(3.6, 4.4, 0.1)) >= 5 and Breakables.shards(Vector3.new(7, 8, 0.1)) <= 14, "de 5 a 14 trozos de cristal")

print("Puertas")
check(Breakables.DoorHits >= 10, ("una puerta aguanta muchas pedradas (%d)"):format(Breakables.DoorHits))
local hits = 0
for _ = 1, 5 do
	hits = Breakables.doorHits(hits, 1)
end
check(hits == 5, "pedradas seguidas se van sumando")
check(Breakables.doorHits(hits, Breakables.DoorHeal + 1) == 1, "si pasa un rato sin golpes, se recupera y vuelve a empezar")
check(Breakables.doorDamage(0) == 0 and Breakables.doorDamage(Breakables.DoorHits / 2) > 0 and Breakables.doorDamage(Breakables.DoorHits) <= 0.5, "se ve cada vez más estropeada (sin ponerse negra del todo)")
local rising = true
for n = 1, Breakables.DoorHits - 1 do
	if Breakables.doorDamage(n + 1) <= Breakables.doorDamage(n) then
		rising = false
	end
end
check(rising, "cada pedrada se nota un poco más")

print("Coger piedras")
check(Breakables.canPickFrom(Enum.Material.Grass) and Breakables.canPickFrom(Enum.Material.Sand) and Breakables.canPickFrom(Enum.Material.Ground), "de césped, arena o tierra, sí")
check(not Breakables.canPickFrom(Enum.Material.Asphalt) and not Breakables.canPickFrom(Enum.Material.WoodPlanks), "del asfalto o de un suelo de madera, no")

print("Puntería")
local g = 196.2 * Breakables.GravityScale
local speed = Breakables.ThrowSpeed
local function lands(from, target)
	local v = Breakables.launch(from, target, speed, g)
	-- ¿Pasa cerca del objetivo?
	local best = math.huge
	for step = 0, 400 do
		local p = Breakables.positionAt(from, v, g, step / 100)
		best = math.min(best, (p - target).Magnitude)
	end
	return best, v
end
local from = Vector3.new(0, 5, 0)
for _, case in {
	{ "una ventana a 10 studs", Vector3.new(0, 7, -10) },
	{ "una ventana en un segundo piso a 30 studs", Vector3.new(12, 18, -28) },
	{ "algo en el suelo a 20 studs", Vector3.new(-15, 0.5, -13) },
	{ "algo lejos, a 90 studs", Vector3.new(60, 8, -67) },
} do
	local miss, v = lands(from, case[2])
	check(miss < 0.6, ("da en %s (a %.2f)"):format(case[1], miss))
	check(math.abs(v.Magnitude - speed) < 0.01, "…a la velocidad de siempre")
end
local vFar = Breakables.launch(from, Vector3.new(0, 5, -5000), speed, g)
local angle = math.deg(math.atan(vFar.Y / Vector3.new(vFar.X, 0, vFar.Z).Magnitude))
check(math.abs(angle - 45) < 0.5, "si está demasiado lejos, la tira a 45° (lo más lejos posible)")
local vUp = Breakables.launch(from, Vector3.new(0, 30, 0), speed, g)
check(vUp.Y > 0 and math.abs(vUp.X) < 0.01, "justo encima: hacia arriba")
local vLow = Breakables.launch(from, Vector3.new(0, 5, -20), speed, g)
check(vLow.Y > 0 and vLow.Y < speed * 0.2, "tiro tenso (no hace una parábola enorme para algo cerca)")

-- El mapa construido (opcional)
local placePath = process.args[1]
if placePath and fs.isFile(placePath) then
	print("Mapa (" .. placePath .. ")")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local glass, doors, cars = 0, 0, 0
	for _, d in game:GetService("Workspace"):GetDescendants() do
		if d:IsA("BasePart") then
			if Breakables.isGlass(d.Name, d.Material, d.Size) then
				glass += 1
				if d.Parent and d.Parent.Name == "ParkedCar" then
					cars += 1
				end
			elseif Breakables.isDoor(d.Name, d.Size) then
				doors += 1
			end
		end
	end
	check(glass > 5000, ("ventanas que se pueden romper: %d"):format(glass))
	check(cars > 1000, ("cristales de coches aparcados: %d"):format(cars))
	check(doors > 1000, ("puertas que se pueden tirar: %d"):format(doors))
end

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
