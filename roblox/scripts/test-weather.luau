-- Prueba de cómo afecta la lluvia y la nieve (shared/Wetness) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-weather.luau
--
-- Comprueba que:
--   * lo mojado se ve más oscuro y el asfalto brilla (más en el suelo que en las paredes)
--   * con nieve, lo de arriba se pone blanco y la calzada casi no
--   * con el suelo mojado o nevado, los vehículos agarran menos; las motos y bicis, aún menos
--   * con poco agarre acelera, frena y gira peor, y derrapa (tarda en ir hacia donde apunta)
--   * una persona se moja bajo la lluvia y se seca a cubierto
--   * el tráfico va más despacio con lluvia y con nieve

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Enum = roblox.Enum
local env = setmetatable({ Enum = Enum, Vector3 = roblox.Vector3 }, { __index = getfenv(1) })
local Wetness = luau.load(fs.readFile("src/shared/Wetness.luau"), { debugName = "Wetness", environment = env })()

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

print("Superficies")
local d0, r0, w0 = Wetness.surface(Enum.Material.Asphalt, 0, 0, true)
check(d0 == 0 and r0 == 0 and w0 == 0, "seco y sin nieve: no cambia nada")
local d1, r1 = Wetness.surface(Enum.Material.Asphalt, 1, 0, true)
check(d1 > 0.1 and r1 > 0.2, "asfalto mojado: más oscuro y con reflejos")
local _, rWall = Wetness.surface(Enum.Material.Asphalt, 1, 0, false)
check(rWall < r1, "en una pared brilla menos que en el suelo")
local _, rGrass = Wetness.surface(Enum.Material.Grass, 1, 0, true)
check(rGrass < r1 * 0.5, "la hierba mojada casi no brilla")
local _, _, wRoof = Wetness.surface(Enum.Material.Slate, 0, 1, true)
local _, _, wRoad = Wetness.surface(Enum.Material.Asphalt, 0, 1, true)
local _, _, wWall = Wetness.surface(Enum.Material.Brick, 0, 1, false)
check(wRoof > 0.5 and wRoad < wRoof and wWall == 0, "nieve: tejados blancos, calzada poco, paredes nada")
check(not Wetness.canGetWet(Enum.Material.Glass, 0) and not Wetness.canGetWet(Enum.Material.Neon, 0), "el cristal y las luces no se tocan")
check(not Wetness.canGetWet(Enum.Material.Concrete, 0.8), "lo casi transparente no se toca")
check(Wetness.level(0.07) == 0 and Wetness.level(0.52) == 0.6 and Wetness.level(3) == 1, "niveles por pasos (menos repintados)")

print("Vehículos")
local dry = Wetness.grip("Coche", 0, 0)
local wet = Wetness.grip("Coche", 1, 0)
local snow = Wetness.grip("Coche", 0, 1)
check(dry == 1, "en seco, agarre completo")
check(wet < dry and snow < wet, "mojado agarra menos, y con nieve aún menos")
check(Wetness.grip("Moto", 1, 0) < wet and Wetness.grip("Bici", 0, 1) < snow, "motos y bicis resbalan más")
check(Wetness.grip("Moto", 1, 1) >= 0.2, "nunca se queda sin nada de agarre")
local roadDry, roadSnow = Wetness.drive(dry), Wetness.drive(snow)
check(roadDry.Accel == 1 and roadDry.Brake == 1 and roadDry.Turn == 1 and roadDry.MaxSpeed == 1, "en seco se conduce igual que antes")
check(roadSnow.Brake < roadSnow.Accel and roadSnow.Turn < 1 and roadSnow.MaxSpeed < 1, "con nieve: frena mucho peor, gira menos y va más despacio")
-- Derrape: gira el volante 90° de golpe y mira cuánto tarda en ir hacia allí
local function settle(grip: number): number
	local traction = Wetness.drive(grip).Traction
	local travel, yaw = 0, math.pi / 2
	local t = 0
	while math.abs(yaw - travel) > 0.1 and t < 10 do
		travel = Wetness.slide(travel, yaw, traction, 1 / 60)
		t += 1 / 60
	end
	return t
end
check(settle(1) < 0.3, ("en seco va enseguida hacia donde apunta (%.2f s)"):format(settle(1)))
check(settle(snow) > settle(1) * 3, ("con nieve derrapa (%.2f s)"):format(settle(snow)))
check(math.abs(Wetness.slide(3.1, -3.1, 10, 1 / 60) - 3.1) < 0.1, "al pasar de 180° a -180° no da la vuelta entera")

print("Personas")
local p = 0
for _ = 1, 60 do
	p = Wetness.person(p, 1, false, 0.5)
end
check(p > 0.9, "30 s bajo la lluvia: empapado")
local q = p
for _ = 1, 20 do
	q = Wetness.person(q, 1, true, 0.5)
end
check(q < p and q > 0, "a cubierto se va secando, poco a poco")
check(Wetness.person(0.5, 0, false, 1) < 0.5, "sin lluvia también se seca")

print("Tráfico")
check(Wetness.trafficSpeed(0, 0) == 1, "en seco, a su velocidad")
check(Wetness.trafficSpeed(1, 0) < 1 and Wetness.trafficSpeed(0, 1) < Wetness.trafficSpeed(1, 0), "más despacio con lluvia y aún más con nieve")

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
