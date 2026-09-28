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

print("▶ Conducir sin carnet (solo si te ve la policía)")
check(Wanted.starsAfter(0, "SinCarnet") == 1 and Wanted.starsAfter(0, "MenorVolante") == 1, "conducir sin carnet o siendo menor: 1 estrella")
check(Wanted.starsAfter(Wanted.starsAfter(0, "SinCarnet"), "Huida") == 2, "si no paras ante el «¡Alto!»: 2 estrellas")
check(Wanted.appliesTo("MenorVolante", false) and Wanted.appliesTo("Huida", false), "un niño al volante también cuenta (la policía le para)")
check(not Wanted.appliesTo("Agresion", false) and Wanted.appliesTo("Agresion", true), "los demás delitos siguen siendo solo desde adolescente")
check(Wanted.DriveSight >= 60 and Wanted.DriveSight <= 80 and Wanted.DriveSight < Wanted.PoliceSight, "una patrulla ve quién conduce a 60-80 studs")
check(Wanted.StopSeconds > 0 and Wanted.StopSpeed > 0, "tras el «¡Alto!» hay un momento para parar")
check(Wanted.Patrols.Max >= 1 and Wanted.Patrols.Spawn[1] > Wanted.DriveSight, "las patrullas de ronda no aparecen delante de tus narices")

local roblox = require("@lune/roblox")
local env = setmetatable({ Vector3 = roblox.Vector3 }, { __index = _G })
local Gameplay = luau.load(fs.readFile("src/shared/Gameplay.luau"), { debugName = "Gameplay", environment = env })()
check(Gameplay.drivingOffence("Adulto", false, "Coche") == "SinCarnet", "adulto sin carnet de coche: «Conducir sin carnet»")
check(Gameplay.drivingOffence("Adulto", true, "Coche") == nil, "con carnet, nada")
check(Gameplay.drivingOffence("Adolescente", false, "Moto") == "MenorVolante" and Gameplay.drivingOffence("Nino", false, "Coche") == "MenorVolante", "un menor con moto o coche: «Menor al volante»")
check(Gameplay.drivingOffence("Nino", false, "Bici") == nil and Gameplay.drivingOffence("Adulto", false, "Patinete") == nil, "bici, patinete y monopatín no piden carnet")
check(Gameplay.DriveMinStage == "Nino", "se conduce desde niño (los bebés no)")

print("▶ Historial de comportamiento (😇 / 😈)")
local Conduct = luau.load(fs.readFile("src/shared/Conduct.luau"), { debugName = "Conduct" })()
check(Conduct.level(0).Icon == "😇" and Conduct.level(30).Icon == "🚨", "de angelito a oveja negra")
local rising = true
for p = 1, 40 do
	if Conduct.level(p).Min < Conduct.level(p - 1).Min then
		rising = false
	end
end
check(rising, "cuantos más puntos, peor nivel")
check(Conduct.pointsOf("Homicidio") > Conduct.pointsOf("SinCarnet") and Conduct.pointsOf("Inventado") == Conduct.DefaultPoints, "lo grave suma más")
check(Conduct.isMinor("Nino") and Conduct.isMinor("Adolescente") and not Conduct.isMinor("AdultoJoven"), "menores: niños y adolescentes")
check(Conduct.groundedAfter(0) == Conduct.Family.GroundedMinutes and Conduct.groundedAfter(1000) == Conduct.Family.GroundedMax, "el castigo se suma, con un máximo")
check(Conduct.curfew(22) and Conduct.curfew(3) and not Conduct.curfew(12), "castigado: a casa de noche")
check(Conduct.calmed(5, 2) == 3 and Conduct.calmed(1, 9) == 0, "portarse bien borra puntos (sin bajar de 0)")
check(Conduct.Family.Rel < 0 and Conduct.Family.RelArrest < 0 and Conduct.Family.Allowance.Nino > 0, "la familia se enfada y la paga existe")

print("▶ Rondas de las patrullas por las calles")
local Routes = luau.load(fs.readFile("src/server/World/PatrolRoutes.luau"), { debugName = "PatrolRoutes", environment = env })()
local V = roblox.Vector3.new
-- Un cruce en T: 1 (0,0)-(100,0), 2 (100,0)-(200,0), 3 (100,0)-(100,100) y un callejón 4 (200,0)-(200,50)
local segs = {
	{ A = V(0, 0, 0), B = V(100, 0, 0) },
	{ A = V(100, 0, 0), B = V(200, 0, 0) },
	{ A = V(100, 0, 0), B = V(100, 0, 100) },
	{ A = V(200, 0, 0), B = V(200, 0, 50) },
}
local graph = Routes.graph(segs)
local nextIndex, from = Routes.next(graph, 1, "B", function()
	return 1
end)
check((nextIndex == 2 or nextIndex == 3) and from == "A", "al final de la calle sigue por otra del cruce")
local seenOptions = {}
for pick = 1, 2 do
	local i = Routes.next(graph, 1, "B", function()
		return pick
	end)
	seenOptions[i] = true
end
check(seenOptions[2] and seenOptions[3] and not seenOptions[1], "no da la vuelta si hay otro camino")
local deadIndex, deadFrom = Routes.next(graph, 4, "B")
check(deadIndex == 4 and deadFrom == "B", "en un callejón sin salida, da la vuelta")
local p0, dir = Routes.point(segs[1], "A", 0, 5)
local p1 = Routes.point(segs[1], "B", 0, 5)
check(math.abs(p0.X) < 0.01 and math.abs(p0.Z - 5) < 0.01 and dir.X > 0.99, "va por su carril (a la derecha)")
check(math.abs(p1.X - 100) < 0.01 and math.abs(p1.Z + 5) < 0.01, "en sentido contrario, por el otro carril")
check(math.abs(Routes.length(segs[3]) - 100) < 0.01, "largo de un tramo")

print()
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
