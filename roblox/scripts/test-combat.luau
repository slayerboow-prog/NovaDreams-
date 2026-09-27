-- Comprueba las reglas del combate (src/shared/Combat.luau).
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-combat.luau

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local Combat = luau.load(fs.readFile("src/shared/Combat.luau"), { debugName = "Combat" })()

local failures = 0
local function check(condition: any, message: string)
	if condition then
		print("  ✅ " .. message)
	else
		failures += 1
		print("  ❌ " .. message)
	end
end

print("▶ Daño")
check(Combat.damage(1, 0, false) == 8, "Puñetazo normal: 8")
check(Combat.damage(3, 0, false) == 15, "Golpe fuerte (tercero del combo): 15")
check(Combat.damage(1, 10, false) == 11, "Con 10 de Fuerza pega un 40% más (8 → 11)")
check(Combat.damage(3, 0, true) == 3, "Defendiéndote de cara solo pasa el 20% (15 → 3)")
check(Combat.damage(1, 0, true) >= 1, "Un golpe defendido siempre quita al menos 1")
check(Combat.damage(99, 0, false) == 15, "Un combo fuera de rango cuenta como el último golpe")

print("▶ Combo")
check(Combat.nextCombo(0, 0, 10) == 1, "Empieza por el primer golpe")
check(Combat.nextCombo(1, 10, 10.5) == 2, "Pulsando a tiempo se encadena el segundo")
check(Combat.nextCombo(2, 10, 10.5) == 3, "…y el tercero (golpe fuerte)")
check(Combat.nextCombo(3, 10, 10.5) == 1, "Después del tercero vuelve a empezar")
check(Combat.nextCombo(1, 10, 11.5) == 1, "Si tardas demasiado, vuelve al primero")

print("▶ Pausas entre golpes")
check(Combat.ready(0, 0, 0), "El primer golpe sale enseguida")
check(not Combat.ready(1, 10, 10.1), "No se puede pegar sin parar (pausa tras el primero)")
check(Combat.ready(1, 10, 10.4), "Tras la pausa, sí")
check(not Combat.ready(3, 10, 10.4), "Tras el golpe fuerte la pausa es más larga")
check(Combat.ready(3, 10, 10.7), "…y luego se puede volver a pegar")

print("▶ K.O.")
local health, ko = Combat.apply(50, 8)
check(health == 42 and not ko, "Con vida de sobra solo baja la vida")
health, ko = Combat.apply(5, 8)
check(health == 1 and ko, "Al quedarte sin vida no mueres: K.O. con 1 de vida")
check(Combat.KOHealth > 0 and Combat.KOHealth < 1, "Te levantas con parte de la vida")

print()
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
