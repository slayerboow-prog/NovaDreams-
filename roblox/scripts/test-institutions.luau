-- Comprueba las reglas de las instituciones: rangos y sueldos (shared/Institutions),
-- condenas (shared/Justice) y la renta (shared/Taxes).
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-institutions.luau

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

-- (Institutions usa Color3: se le da el de Lune)
local function load(path: string): any
	return luau.load(fs.readFile(path), { debugName = path, environment = { Color3 = roblox.Color3 } })()
end
local Institutions = load("src/shared/Institutions.luau")
local Justice = load("src/shared/Justice.luau")
local Taxes = load("src/shared/Taxes.luau")

local failures = 0
local function check(condition: any, message: string)
	if condition then
		print("  ✅ " .. message)
	else
		failures += 1
		print("  ❌ " .. message)
	end
end

print("▶ Instituciones y rangos")
for _, id in { "Policia", "Justicia", "Prisiones", "Ejercito", "Hacienda" } do
	local inst = Institutions.List[id]
	local ordered = true
	for i = 2, #inst.Ranks do
		if inst.Ranks[i].Points <= inst.Ranks[i - 1].Points or inst.Ranks[i].Bonus < inst.Ranks[i - 1].Bonus then
			ordered = false
		end
	end
	check(inst and inst.Ranks[1].Points == 0 and ordered, id .. ": se empieza desde abajo y cada rango pide y paga más")
	check(inst.Ranks[#inst.Ranks].Name == inst.Chief, id .. ": el rango más alto es el jefe (" .. inst.Chief .. ")")
end
local army = Institutions.List.Ejercito
check(select(2, Institutions.rankFor(army, 0)).Id == "Soldado", "Con 0 puntos: Soldado")
check(select(2, Institutions.rankFor(army, 65)).Id == "Sargento", "Con 65 puntos: Sargento")
check(Institutions.toNext(army, 65) == 55, "A un sargento con 65 le faltan 55 para teniente")
check(Institutions.toNext(army, 9999) == nil and Institutions.isTop(army, 9999), "Con muchos puntos: General (no hay más)")
check(Institutions.pay(army, 0, 100) == 100, "Un soldado cobra el sueldo base")
check(Institutions.pay(army, 600, 100) > 100, "Un general cobra más")
check(Institutions.byJob("Juez") == Institutions.List.Justicia, "El oficio Juez es de Justicia")
check(Institutions.byJob("Barista") == nil, "Barista no es una institución del Estado")

print("▶ Condenas")
local fine1, jail1 = Justice.automatic(1)
local fine5, jail5 = Justice.automatic(5)
check(fine1 > 0 and jail1 > 0, "La sentencia automática lleva multa y prisión")
check(fine5 > fine1 and jail5 > jail1, "Con más estrellas, más multa y más prisión")
local f, s = Justice.verdict("Absolver", 3)
check(f == 0 and s == 0, "Absolver: ni multa ni prisión")
f, s = Justice.verdict("Multa", 3)
check(f == 3 * Justice.FinePerStar and s == 0, "Solo multa")
f, s = Justice.verdict("Prision", 3, 4)
check(s == 240 and f > 0, "Prisión de 4 minutos (y multa)")
f, s = Justice.verdict("Prision", 3, 99)
check(s == Justice.MaxMinutes * 60, "El juez no puede pasar del máximo")
check(Justice.afterWork(100) == 100 - Justice.WorkReduction, "Trabajar en prisión reduce la condena")
check(Justice.afterWork(5) == 0, "…pero nunca por debajo de cero")

print("▶ Renta")
check(Taxes.due(100) == 0, "Por debajo del mínimo exento no se paga")
check(Taxes.due(1150) == 100, "Se paga el 10% de lo que pasa del mínimo (1150 → 100)")
check(Taxes.withSurcharge(100) == 120, "La inspección añade un 20% de recargo")

print()
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
