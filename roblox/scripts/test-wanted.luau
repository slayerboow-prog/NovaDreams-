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

print("▶ Las patrullas miran hacia donde van (también tras dar la vuelta)")
-- El coche patrulla se orienta con PatrolRoutes.turnToward (PoliceUnits.stepPatrol). Antes era
-- look:Lerp(dir): en un callejón sin salida dir = -look y la mezcla nunca cambiaba de sentido,
-- así que el coche seguía mirando hacia atrás (circulaba marcha atrás) hasta el siguiente cruce.
do
	-- Simula PoliceUnits.stepPatrol: avanza por la calle, se arrima al carril poco a poco (blend) y
	-- gira con `turn`. Devuelve los segundos mirando hacia atrás (LookVector·velocidad < 0), el
	-- peor valor y cuántas medias vueltas ha dado.
	local function drive(segments, startIndex: number, seconds: number, turn): (number, number, number)
		local g = Routes.graph(segments)
		local index, fromSide, t = startIndex, "A", 0.5
		local pos, look = Routes.point(g.Segments[index], fromSide, t, 5)
		local dt, speed = 1 / 30, 24
		local backwards, worst, uTurns, streak, longest = 0, 1, 0, 0, 0
		for _ = 1, math.floor(seconds / dt) do
			t += speed * dt / Routes.length(g.Segments[index])
			if t >= 1 then
				local before = index
				local arrived = if fromSide == "A" then "B" else "A"
				index, fromSide = Routes.next(g, index, arrived, function()
					return 1
				end)
				if index == before and fromSide == arrived then
					uTurns += 1
				end
				t = Routes.entry(g.Segments[index], fromSide, pos)
			end
			local point, dir = Routes.point(g.Segments[index], fromSide, t, 5)
			local nextPos = pos:Lerp(point, math.min(1, dt * 6))
			local velocity = nextPos - pos
			pos = nextPos
			look = turn(look, dir, dt)
			if velocity.Magnitude > 0.05 then
				local dot = look:Dot(velocity.Unit)
				worst = math.min(worst, dot)
				if dot < 0 then
					backwards += dt
					streak += dt
					longest = math.max(longest, streak)
				else
					streak = 0
				end
			end
		end
		return backwards, worst, uTurns, longest
	end
	local function newTurn(look, dir, dt)
		return Routes.turnToward(look, dir, 3.5 * dt)
	end
	local function oldTurn(look, dir, dt) -- (lo de antes en PoliceUnits.stepPatrol)
		local turned = look:Lerp(dir, math.min(1, dt * 4))
		return if turned.Magnitude > 0.01 then turned.Unit else dir
	end
	-- Una calle sin salida: va y vuelve (una media vuelta en cada punta)
	local deadEnd = { { A = V(0, 0, 0), B = V(0, 0, -120) } }
	local oldBack = drive(deadEnd, 1, 20, oldTurn)
	check(oldBack > 8, ("(antes: tras la primera media vuelta iba marcha atrás: %.1f de 20 s)"):format(oldBack))
	local backwards, _, uTurns = drive(deadEnd, 1, 20, newTurn)
	check(uTurns >= 3 and backwards / uTurns < 0.7, ("en un callejón sin salida da media vuelta enseguida (%.2f s mirando atrás en cada una)"):format(backwards / math.max(uTurns, 1)))
	local turned = Routes.turnToward(V(0, 0, -1), V(0, 0, 1), 0.2)
	check(turned:Dot(V(0, 0, -1)) < 0.999 and math.abs(turned.Magnitude - 1) < 1e-3, "en media vuelta exacta empieza a girar (antes se quedaba mirando atrás)")
	local done = V(0, 0, -1)
	for _ = 1, 40 do
		done = Routes.turnToward(done, V(0, 0, 1), 0.12)
	end
	check(done:Dot(V(0, 0, 1)) > 0.999, "y acaba mirando hacia donde va")
	check(Routes.turnToward(V(1, 0, 0), V(0, 0, -1), 10):Dot(V(0, 0, -1)) > 0.999, "un giro pequeño se hace entero")
	-- Una vuelta a la manzana: cuatro calles en cuadrado
	local square = {
		{ A = V(0, 0, 0), B = V(200, 0, 0) },
		{ A = V(200, 0, 0), B = V(200, 0, 200) },
		{ A = V(200, 0, 200), B = V(0, 0, 200) },
		{ A = V(0, 0, 200), B = V(0, 0, 0) },
	}
	local _, _, _, longest = drive(square, 1, 60, newTurn)
	check(longest < 0.4, ("dando vueltas a la manzana no va marcha atrás (como mucho %.2f s seguidos mirando atrás: el giro de la esquina)"):format(longest))
	local source = fs.readFile("src/server/World/PoliceUnits.luau")
	check(source:find("PatrolRoutes.turnToward", 1, true) ~= nil and not source:find("look:Lerp(dir", 1, true), "PoliceUnits gira las patrullas con turnToward (no con Lerp)")
end

-- Delitos con los servicios de verdad (scripts/lib/CrimeHarness): el modo pruebas no libra a un
-- niño de la policía, un niño normal sí se libra (solo aviso), y agredir a un agente escala.
local okRun, runError = pcall(function()
	local task = require("@lune/task")
	local H = require("./lib/CrimeHarness")
	H.boot()
	local W = H.WantedService
	local wait = H.Wanted.CallDelay + 0.6

	print("▶ Menores y modo pruebas")
	local kid = H.player("Niño", 6001, "Nino", V(0, 0, 0))
	local witness = H.npc("Testigo", V(0, 0, -10))
	local mark = #H.sent
	W.crime(kid, "Agresion")
	task.wait(wait)
	check(kid:GetAttribute("Wanted") == nil and H.dispatch[kid] == nil, "un niño normal no tiene estrellas (sin modo pruebas)")
	check(H.noticeHas(kid, "Si fueras mayor", mark), "solo el aviso «Si fueras mayor, vendría la policía»")
	local owner = H.player("Dueño", H.CREATOR, "Nino", V(500, 0, 0))
	H.npc("Testigo2", V(500, 0, -10))
	mark = #H.sent
	W.crime(owner, "Agresion")
	task.wait(wait)
	check(owner:GetAttribute("Wanted") == 1 and H.dispatch[owner] == 1, "un niño tester con «Sin requisitos»: 1 estrella y una patrulla")
	check(not H.noticeHas(owner, "Si fueras mayor", mark) and H.noticeHas(owner, "Modo pruebas", mark), "con el aviso del modo pruebas, no el de «Si fueras mayor»")
	mark = #H.sent
	W.crime(owner, "Agresion")
	task.wait(wait)
	check(#H.notices(owner, mark) == 0 or not H.noticeHas(owner, "Modo pruebas", mark), "el aviso del modo pruebas sale una sola vez")
	W.clear(owner)
	check(owner:GetAttribute("Wanted") == nil and H.dispatch[owner] == nil, "quitar la búsqueda retira las patrullas")
	H.profiles[owner].Tester = { Bypass = false }
	W.crime(owner, "Agresion")
	task.wait(wait)
	check(owner:GetAttribute("Wanted") == nil, "con «Sin requisitos» apagado vuelve a ser un niño para la policía")
	H.profiles[owner].Tester.Bypass = true
	check(witness.Parent ~= nil, "(el testigo sigue ahí)")

	print("▶ Agredir a un agente de policía")
	local adult = H.player("Adulto", 6002, "Adulto", V(1000, 0, 0))
	local officer = H.officer(V(1000, 0, -5))
	local result = H.CombatService.applyHit(adult, officer, { Amount = 25, Direction = V(0, 0, -1), Weapon = "Pistola" })
	task.wait(0.1)
	check(result.Hit and officer:GetAttribute("Hp") == 15, "el agente recibe el daño")
	check(adult:GetAttribute("Wanted") == H.Wanted.Crimes.AgresionPolicia.Stars, "al momento: estrellas por agredir a un agente (sin esperar testigos)")
	check(H.dispatch[adult] == adult:GetAttribute("Wanted"), "y salen las patrullas de esas estrellas")
	H.CombatService.applyHit(adult, officer, { Amount = 25, Direction = V(0, 0, -1), Weapon = "Pistola" })
	task.wait(0.1)
	check(adult:GetAttribute("Wanted") == 2 * H.Wanted.Crimes.AgresionPolicia.Stars, "otro disparo al agente: la búsqueda escala")
	check(officer:GetAttribute("Down") == true, "el agente cae al quedarse sin vida")

	print("▶ Disparar a un personaje de la calle (sin jugador de por medio)")
	local shooter = H.player("Tirador", 6003, "Adulto", V(1500, 0, 0))
	local passer = H.npc("Paseante", V(1500, 0, -80)) -- (lejos: ningún otro testigo cerca)
	H.CombatService.applyHit(shooter, passer, { Amount = 30, Direction = V(0, 0, -1), Weapon = "Fusil" })
	task.wait(wait)
	check(shooter:GetAttribute("Wanted") == H.Wanted.Crimes.Disparo.Stars, "la víctima llama aunque esté lejos: «Disparar a una persona»")
	local toy = H.player("Juguete", 6004, "Adulto", V(2000, 0, 0))
	local wet = H.npc("Mojado", V(2000, 0, -10))
	H.CombatService.applyHit(toy, wet, { Amount = 0, Direction = V(0, 0, -1), Weapon = "PistolaAgua", Toy = true })
	task.wait(wait)
	check(toy:GetAttribute("Wanted") == nil, "una pistola de agua no es delito")
end)
check(okRun, "las pruebas con los servicios terminan sin errores" .. (if okRun then "" else ": " .. tostring(runError)))

print()
if failures == 0 then
	print("✅ Todo correcto")
	process.exit(0)
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
