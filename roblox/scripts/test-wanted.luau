-- Comprueba las reglas del nivel de búsqueda (src/shared/Wanted.luau).
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-wanted.luau

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local Wanted = luau.load(fs.readFile("src/shared/Wanted.luau"), { debugName = "Wanted" })()

local failures = 0
local function check(condition: any, message: string)
	if condition then
		print("  ✅ " .. message)
	else
		failures += 1
		print("  ❌ " .. message)
	end
end

print("▶ Estrellas por delito")
check(Wanted.starsAfter(0, "Agresion") == 1, "Pegar a alguien: 1 estrella")
check(Wanted.starsAfter(0, "Atraco") == 2, "Atracar una tienda: 2 estrellas")
check(Wanted.starsAfter(1, "Robo") == 2, "Los delitos se van sumando")
check(Wanted.starsAfter(4, "AgresionPolicia") == 5, "Nunca más de 5 estrellas")
check(Wanted.starsAfter(5, "Atraco") == 5, "Con 5 se queda en 5")
check(Wanted.starsAfter(2, "NoExiste") == 2, "Algo que no es delito no suma")

print("▶ Patrullas")
check(Wanted.response(1).Cars == 1 and Wanted.response(1).Helis == 0, "1★: un coche patrulla")
check(Wanted.response(3).Cars == 3 and Wanted.response(3).Helis == 0, "3★: tres coches, sin helicóptero")
check(Wanted.response(4).Helis == 1, "4★: llega el helicóptero")
check(Wanted.response(5).Cars == 4 and Wanted.response(5).Helis == 2, "5★: cuatro coches y dos helicópteros")
local growing = true
for s = 2, 5 do
	local a, b = Wanted.response(s - 1), Wanted.response(s)
	if b.Cars + b.Helis * 2 < a.Cars + a.Helis * 2 then
		growing = false
	end
end
check(growing, "Cuantas más estrellas, más policía")
check(Wanted.OfficerSpeed[1] < 16 * 1.5, "Corriendo se puede escapar de un agente a pie")

print("▶ Huida y detención")
check(Wanted.evadeSeconds(0) == 0, "Sin estrellas no hay que despistar a nadie")
check(Wanted.evadeSeconds(5) > Wanted.evadeSeconds(1), "Con más estrellas cuesta más despistarles")
check(Wanted.fine(3) == 3 * Wanted.Fine, "La multa depende de las estrellas")

print("▶ Robar a alguien")
check(Wanted.stealAmount(0) == 0, "A quien no lleva dinero no se le quita nada")
check(Wanted.stealAmount(3) == 3, "Nunca más de lo que lleva")
check(Wanted.stealAmount(100) == 15, "Se lleva una parte (15%)")
check(Wanted.stealAmount(100000) == Wanted.StealMax, "Con un máximo por robo")

print()
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
