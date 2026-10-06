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

print("▶ Esquivar (voltereta)")
check(Combat.dodging(10, 10.2) and not Combat.dodging(10, 10 + Combat.DodgeInvulnerable + 0.05), "Al empezar la voltereta los golpes no entran; un momento después, sí")
check(Combat.DodgeCooldown > Combat.RollTime, "No se encadenan volteretas (la pausa es más larga que la voltereta)")
check(Combat.rollSpeed(0) > Combat.rollSpeed(0.5) and Combat.rollSpeed(0.5) > Combat.rollSpeed(1) and Combat.rollSpeed(1) > 0, "Sale rodando con impulso y va frenando")
local combatServer = fs.readFile("src/server/Services/CombatService.luau")
check(combatServer:find("SetAttribute(\"Roll\"", 1, true) ~= nil, "El servidor avisa a todos de la voltereta (atributo Roll) cuando la acepta")

print("▶ K.O.")
local health, ko = Combat.apply(50, 8)
check(health == 42 and not ko, "Con vida de sobra solo baja la vida")
health, ko = Combat.apply(5, 8)
check(health == 1 and ko, "Al quedarte sin vida no mueres: K.O. con 1 de vida")
check(Combat.KOHealth > 0 and Combat.KOHealth < 1, "Te levantas con parte de la vida")

print("▶ Morir y el hospital")
local Hospital = luau.load(fs.readFile("src/shared/Hospital.luau"), { debugName = "Hospital" })()
check(Hospital.bill(1000) == Hospital.Bill, "El hospital cobra su factura")
check(Hospital.bill(40) == 40, "Si no llega, pagas lo que tengas")
check(Hospital.bill(0) == 0, "Sin dinero no pagas nada")
check(Hospital.RespawnSeconds > 0 and table.find(Hospital.Models, "Hospital") ~= nil, "Se reaparece en el hospital al cabo de unos segundos")
local server = fs.readFile("src/server/Services/CombatService.luau")
check(server:find("Killed = true", 1, true) ~= nil, "Rematar a alguien K.O. lo mata (homicidio)")

-- Disparar de verdad (WeaponService.fire -> CombatService.applyHit -> WantedService), con los
-- servicios reales en un Roblox de mentira (scripts/lib/CrimeHarness). Antes: un niño en modo pruebas
-- con un subfusil disparaba a la gente y solo salía «Si fueras mayor, vendría la policía»; y a un
-- NPC de la calle se le podía acribillar sin que la víctima llamase (solo contaba como disparos al aire).
local okRun, runError = pcall(function()
	local roblox = require("@lune/roblox")
	local task = require("@lune/task")
	local H = require("./lib/CrimeHarness")
	H.boot()
	local V = roblox.Vector3.new
	local Wanted = H.Wanted
	local wait = Wanted.CallDelay + 0.6

	print("▶ Disparar a la gente con el modo pruebas (niño tester, «Sin requisitos»)")
	local owner = H.player("Dueño", H.CREATOR, "Nino", V(0, 0, 0))
	check(H.TesterService.bypass(owner), "el dueño es tester con «Sin requisitos» encendido")
	H.give(owner, "Subfusil")
	check(H.WeaponService.equip(owner, "Subfusil"), "el niño tester puede empuñar el subfusil (se salta la edad)")
	local walker = H.npc("Paseante", V(0, 0, -20))
	local mark = #H.sent
	check(H.shoot(owner, walker), "dispara")
	check(H.saidAny(walker, "¡"), "la víctima reacciona al disparo (dice algo)")
	task.wait(wait)
	check((owner:GetAttribute("Wanted") or 0) >= Wanted.Crimes.Disparo.Stars, "le buscan: estrellas por disparar a una persona")
	check((H.dispatch[owner] or 0) >= 1, "y salen patrullas a por él (PoliceUnits.ensure)")
	check(H.saidAny(walker, "📞"), "la víctima llama a la policía")
	check(not H.noticeHas(owner, "Si fueras mayor", mark), "ya no sale «Si fueras mayor, vendría la policía»")
	check(H.noticeHas(owner, "Modo pruebas", mark), "se le explica que en modo pruebas sus delitos cuentan como de adulto")

	print("▶ Lo mismo sin modo pruebas (adulto con licencia)")
	local adult = H.player("Adulto", 5001, "Adulto", V(300, 0, 0))
	check(not H.TesterService.isTester(adult), "no es tester")
	H.licence(adult)
	H.give(adult, "Pistola")
	check(H.WeaponService.equip(adult, "Pistola"), "empuña su pistola")
	local victim = H.npc("Paseante2", V(300, 0, -25))
	check(H.shoot(adult, victim), "dispara")
	task.wait(wait)
	check((adult:GetAttribute("Wanted") or 0) >= Wanted.Crimes.Disparo.Stars, "estrellas por disparar a una persona")
	check((H.dispatch[adult] or 0) >= 1, "y salen patrullas")

	print("▶ Una ráfaga a la misma persona es una denuncia, no cinco")
	local burst = H.player("Rafaga", 5002, "Adulto", V(600, 0, 0))
	H.licence(burst)
	H.give(burst, "Pistola")
	H.WeaponService.equip(burst, "Pistola")
	local target = H.npc("Paseante3", V(600, 0, -20))
	H.shoot(burst, target)
	H.shoot(burst, target)
	task.wait(wait)
	check(burst:GetAttribute("Wanted") == Wanted.Crimes.Disparo.Stars, "dos disparos seguidos a la misma víctima: una denuncia")

	-- Estilo shooter móvil: se dispara andando, saltando y apuntando a la vez; el servidor no lo rechaza
	-- (sigue mirando cadencia, munición y lo demás), solo abre algo más la dispersión en el aire
	print("▶ Disparar moviéndose, saltando y apuntando a la vez")
	local runner = H.player("Corredor", 5004, "Adulto", V(1200, 0, 0))
	H.licence(runner)
	H.give(runner, "Pistola")
	check(H.WeaponService.equip(runner, "Pistola"), "empuña su pistola")
	local runnerHum = runner.Character:FindFirstChildOfClass("Humanoid")
	local runnerRoot = runner.Character:FindFirstChild("HumanoidRootPart")
	local dummy = H.npc("Paseante4", V(1200, 0, -20))
	runnerRoot.AssemblyLinearVelocity = V(16, 0, 0)
	check(H.shoot(runner, dummy), "andando (16 studs/s): el disparo cuenta")
	runner:SetAttribute("Aiming", true)
	check(H.shoot(runner, dummy), "andando y apuntando: cuenta")
	runnerHum.FloorMaterial = roblox.Enum.Material.Air
	runnerRoot.AssemblyLinearVelocity = V(16, 30, 0)
	check(H.shoot(runner, dummy), "saltando, andando y apuntando a la vez: cuenta")
	runner:SetAttribute("Aiming", nil)
	check(H.shoot(runner, dummy), "en el aire sin apuntar: cuenta")
	local before = runner:GetAttribute("WeaponMag")
	check(not H.WeaponService.fire(runner, dummy:FindFirstChild("UpperTorso").Position), "pero la cadencia se sigue respetando (dos tiros sin pausa: el segundo no)")
	check(runner:GetAttribute("WeaponMag") == before, "y ese tiro de más no gasta munición")
	runnerHum.FloorMaterial = roblox.Enum.Material.Plastic
	runnerRoot.AssemblyLinearVelocity = V(0, 0, 0)

	print("▶ Disparar a un agente de policía")
	local cop = H.officer(V(300, 0, 25))
	local before = adult:GetAttribute("Wanted") or 0
	check(H.shoot(adult, cop), "dispara al agente")
	check((adult:GetAttribute("Wanted") or 0) > before, "sube la búsqueda al momento (agresión a un agente)")
	check((cop:GetAttribute("Hp") or 0) < 40, "el agente recibe el daño")

	print("▶ Niño sin modo pruebas: las armas de verdad no")
	local kid = H.player("Niño", 5003, "Nino", V(900, 0, 0))
	H.give(kid, "Pistola")
	mark = #H.sent
	check(not H.WeaponService.equip(kid, "Pistola"), "un niño normal no puede empuñar una pistola")
	check(H.noticeHas(kid, "no son para niños", mark), "y se le dice por qué")
	local profile = H.profiles[owner]
	profile.Tester = profile.Tester or {}
	profile.Tester.Bypass = false
	H.WeaponService.holster(owner)
	check(not H.WeaponService.equip(owner, "Subfusil"), "con «Sin requisitos» apagado, el niño tester tampoco")
	profile.Tester.Bypass = true

	print("▶ Armas de juguete: no son delito, pero se nota")
	local splash = H.player("Mojador", 5004, "Adulto", V(1200, 0, 0))
	H.give(splash, "PistolaAgua")
	check(H.WeaponService.equip(splash, "PistolaAgua"), "empuña la pistola de agua")
	local wet = H.npc("Paseante4", V(1200, 0, -20))
	check(H.shoot(splash, wet), "moja a un paseante")
	local copWet = H.officer(V(1200, 0, 20))
	check(H.shoot(splash, copWet), "y a un agente")
	task.wait(wait)
	check(splash:GetAttribute("Wanted") == nil and H.dispatch[splash] == nil, "sin estrellas ni patrullas")
	check(H.saidAny(wet, "💦"), "el paseante se queja del agua")
	check(H.saidAny(copWet, "gracioso"), "el agente también reacciona")
	check(copWet:GetAttribute("Hp") == 40, "y no pierde vida")

	print("▶ Armas de servicio (la pistola reglamentaria)")
	local civil = H.player("Civil", 5005, "Adulto", V(1500, 0, 0))
	H.give(civil, "PistolaPolicia")
	mark = #H.sent
	check(not H.WeaponService.equip(civil, "PistolaPolicia"), "fuera de turno un jugador normal no la empuña")
	check(H.noticeHas(civil, "solo de turno", mark), "y se le dice: «solo de turno»")
	H.give(owner, "PistolaPolicia")
	mark = #H.sent
	check(H.WeaponService.equip(owner, "PistolaPolicia"), "el tester sí (se la queda al dejar el turno)")
	check(H.noticeHas(owner, "fuera de turno", mark), "con el aviso de que fuera de turno disparar a alguien es delito")

	print("▶ Policía de servicio")
	local officer = H.player("Agente", 5006, "Adulto", V(1800, 0, 0))
	officer:SetAttribute("Job", "Policia")
	check(H.InventoryService.count(officer, H.Weapons.itemId("Taser")) == 1, "al empezar el turno le dan el táser y la pistola")
	check(H.WeaponService.equip(officer, "Taser"), "empuña el táser")
	local thief = H.npc("Ladron", V(1800, 0, -15), { Suspect = true })
	check(H.shoot(officer, thief), "le da con el táser al ladrón de su aviso")
	task.wait(wait)
	check(officer:GetAttribute("Wanted") == nil, "reducir al sospechoso de su aviso con el táser no es delito")
	local bystander = H.npc("Paseante5", V(1800, 0, 15))
	H.profiles[officer].WeaponMags.Taser = H.Weapons.get("Taser").Magazine -- (recargado)
	check(H.shoot(officer, bystander), "le da con el táser a un paseante")
	task.wait(wait)
	check((officer:GetAttribute("Wanted") or 0) >= 1, "pero a un paseante, sí (agresión)")

	print("▶ Cristales y puertas: las balas de verdad los rompen; las de juguete no")
	local vandal = H.player("Cristalero", 5007, "Adulto", V(2100, 0, 0))
	H.licence(vandal)
	H.give(vandal, "Pistola")
	H.WeaponService.equip(vandal, "Pistola")
	local pane = H.part("Glass", V(2100, 3, -15), V(4, 6, 0.2))
	pane.Breakable = true
	table.clear(H.breakCalls)
	check(H.shootPart(vandal, pane), "dispara al escaparate")
	local call = H.breakCalls[1]
	check(call ~= nil and call.Kind == "Bullet" and call.Part == pane and call.Weapon == "Real", "la bala llega a BreakService (cristal, arma de verdad)")
	H.give(vandal, "Escopeta")
	H.WeaponService.equip(vandal, "Escopeta")
	table.clear(H.breakCalls)
	H.shootPart(vandal, pane)
	check(#H.breakCalls == 1, ("los perdigones de la escopeta golpean la pieza una vez por disparo (%d)"):format(#H.breakCalls))
	local wetter = H.player("Mojador2", 5008, "Adulto", V(2400, 0, 0))
	H.give(wetter, "PistolaAgua")
	H.WeaponService.equip(wetter, "PistolaAgua")
	local pane2 = H.part("Glass", V(2400, 3, -15), V(4, 6, 0.2))
	table.clear(H.breakCalls)
	check(H.shootPart(wetter, pane2), "dispara con la pistola de agua al cristal")
	check(#H.breakCalls == 0, "el agua no rompe cristales (ni llega a BreakService)")
	H.give(wetter, "Paintball")
	H.WeaponService.equip(wetter, "Paintball")
	H.shootPart(wetter, pane2)
	check(#H.breakCalls == 0, "la pintura tampoco")

	print("▶ Golpes sin nadie delante: patadas a puertas y cristales")
	local kicker = H.player("Pateador", 5009, "Adulto", V(2700, 0, 0))
	table.clear(H.breakCalls)
	local combat = H.remotes.Combat
	-- (ligero, ligero y fuerte: el final es un golpe fuerte; "Attack" es el ligero de antes)
	for _, kind in { "Attack", "Light", "Heavy" } do
		combat.OnServerEvent:Fire(kicker, kind)
		task.wait(0.5)
	end
	local melee, heavy = 0, false
	for _, c in H.breakCalls do
		if c.Kind == "Melee" and c.Player == kicker then
			melee += 1
			heavy = heavy or c.Heavy == true
		end
	end
	check(melee >= 3, ("cada golpe al aire mira si hay un cristal o una puerta delante (%d)"):format(melee))
	check(heavy, "el final con el golpe fuerte rompe cristales (Heavy)")

	print("▶ El estilo de combos (más en scripts/test-combos.luau)")
	task.wait(1)
	check(H.CombatService.handle(kicker, "Attack") == "L1", "«Attack» (el de antes) es el primer golpe ligero del combo")
	task.wait(0.3)
	check(H.CombatService.handle(kicker, "Light") == "L2", "y «Light» sigue el combo")
	task.wait(0.3)
	check(H.CombatService.handle(kicker, "Heavy", false) == "Lanzador", "ligero ×2 + fuerte: el lanzador")
	local bars = kicker:GetAttribute("Aguante") ~= nil and kicker:GetAttribute("Guardia") ~= nil
	check(bars, "el cliente recibe las barras de aguante y guardia (atributos)")
	check(kicker:GetAttribute("Energia") == nil, "sin la energía despierta (Saga de la Grieta) no hay barra de energía")
end)
check(okRun, "las pruebas de disparos terminan sin errores" .. (if okRun then "" else ": " .. tostring(runError)))

print()
if failures == 0 then
	print("✅ Todo correcto")
	process.exit(0)
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
