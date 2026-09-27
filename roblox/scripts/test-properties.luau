-- Comprueba las reglas de las viviendas (src/shared/Properties.luau).
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-properties.luau

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local Properties = luau.load(fs.readFile("src/shared/Properties.luau"), { debugName = "Properties" })()

local failures = 0
local function check(condition: any, message: string)
	if condition then
		print("  ✅ " .. message)
	else
		failures += 1
		print("  ❌ " .. message)
	end
end

print("▶ Precios")
local casa = Properties.price("Casa", 0, "Casa_100_200#0")
check(casa == Properties.price("Casa", 0, "Casa_100_200#0"), "La misma vivienda siempre cuesta lo mismo")
check(casa >= Properties.Base.Casa * 0.85 and casa <= Properties.Base.Casa * 1.16, "Una casa cuesta alrededor de su precio base")
check(Properties.price("Villa", 0, "V#0") > Properties.price("Casa", 0, "V#0"), "Una villa es más cara que una casa")
check(Properties.price("Piso", 12, "P#12") > Properties.price("Piso", 1, "P#12"), "Un piso alto es algo más caro (misma vivienda)")
check(casa % 10 == 0, "Los precios son redondos")
check(Properties.sellPrice(1000) == 700, "Al vender te devuelven el 70%")

print("▶ Vecinos")
local neighbors, total = 0, 2000
for i = 1, total do
	if Properties.isNeighborHome("Portal_" .. i .. "_" .. (i * 7) .. "#" .. (i % 9 + 1)) then
		neighbors += 1
	end
end
check(neighbors > total * 0.4 and neighbors < total * 0.6, ("Más o menos la mitad de las viviendas tienen vecinos (%d de %d)"):format(neighbors, total))
check(Properties.isNeighborHome("X#3") == Properties.isNeighborHome("X#3"), "Siempre los mismos vecinos en la misma vivienda")
local names = Properties.neighbors("Portal_1_2#3")
check(#names >= 1 and #names <= 3, "Entre 1 y 3 vecinos por vivienda")
check(string.find(names[1], " ") ~= nil, "El primero con nombre y apellido: " .. names[1])
local same = Properties.neighbors("Portal_1_2#3")
check(same[1] == names[1], "La misma vivienda, los mismos nombres")
check(Properties.unitKey("Casa_1_2", 0) == "Casa_1_2#0", "Cada vivienda tiene su nombre (edificio + planta)")

print()
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
