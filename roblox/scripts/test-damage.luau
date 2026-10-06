-- Prueba del daño por puntos FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-damage.luau
--
-- Comprueba que:
--   * cada bala quita el daño de su arma (Weapons.damageAt): más en la cabeza, menos en brazos y
--     piernas y menos de lejos; los golpes, las piedras y el botón de atacar, el suyo (EnemyStats)
--   * los enemigos de misión tienen vida por puntos (las misiones de antes: HP = N golpes -> N × 25);
--     las armas de fuego les hacen su daño × FirearmMultiplier (la mejor opción); la pistola de agua
--     les hace su daño a los «de juguete» (cucarachas) y muy poco a los demás (robots, jefes)
--   * todo pasa por el SERVIDOR (DamageService.apply): solo el dueño del combate daña a sus enemigos,
--     el daño se limita, y el cliente no tiene forma de aplicar daño (el remoto Damage solo avisa)
--   * el enemigo cae al llegar a 0 (y ya no recibe más) y el paso Fight se completa cuando caen todos
--   * el jugador cae en combate al quedarse sin vida: en una pelea, K.O. (Fallen = "Combat") y luego
--     siempre al hospital (salvo detenido); en una misión, el combate vuelve a empezar desde el
--     principio del paso sin perder la misión
--   * el cliente pinta barras de vida, números (amarillos en la cabeza, agrupados) y el borde rojo

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L = require("./lib/ModuleLoader")

local V = roblox.Vector3.new

local failures = 0
local function check(condition: any, message: string)
	if condition then
		print("  ✅ " .. message)
	else
		failures += 1
		print("  ❌ " .. message)
	end
end

local EnemyStats = L.load("src/shared/EnemyStats")
local Weapons = L.load("src/shared/Weapons")

---------------------------------------------------------------------
print("▶ Daño de cada bala (Weapons.damageAt)")
local pistol = Weapons.get("Pistola")
local near = Weapons.damageAt(pistol, 10, "Torso")
check(near == pistol.Damage, ("Pistola de cerca, en el cuerpo: %d (su daño)"):format(near))
check(Weapons.damageAt(pistol, 10, "Head") == math.floor(pistol.Damage * pistol.Head + 0.5), "En la cabeza, con su multiplicador (×" .. pistol.Head .. ")")
check(Weapons.damageAt(pistol, 10, "Limb") < near, "En brazos y piernas, menos")
check(Weapons.damageAt(pistol, pistol.Falloff.End + 1, "Torso") < near, "De lejos, menos (caída por distancia)")
check(Weapons.damageAt(pistol, pistol.Range + 5, "Torso") == 0, "Más allá del alcance, nada")
check(Weapons.damageAt(Weapons.get("PistolaAgua"), 5, "Head") == 0, "La pistola de agua no hace daño a las personas (Damage = 0)")

---------------------------------------------------------------------
print("\n▶ Vida de los enemigos (shared/EnemyStats)")
check(EnemyStats.maxHealth({ Npc = "Cucaracha1" }, { HP = 2 }) == 50, "«HP = 2 golpes» de antes = 50 puntos")
check(EnemyStats.maxHealth({ Npc = "Cucaracha3", HP = 3 }, { HP = 2 }) == 75, "El HP del enemigo manda sobre el del paso (3 golpes = 75)")
check(EnemyStats.maxHealth({ Npc = "Cosimo", Health = 300 }, { HP = 6 }) == 300, "Un enemigo puede llevar su vida en puntos")
check(EnemyStats.maxHealth({ Npc = "Cucaracha9" }, nil) < EnemyStats.maxHealth({ Npc = "PolloGigante" }, nil), "Sin datos de la misión: la cucaracha tiene poca vida y Petra mucha (su tipo)")
check(EnemyStats.kindOf("Cucaracha3") == "Cucaracha" and EnemyStats.kindOf("PolloGigante") == "GallinaGigante" and EnemyStats.kindOf("RobotSeguridad") == "Robot", "Cada enemigo es de su tipo")
check(EnemyStats.typeOf("Cosimo").Boss and EnemyStats.typeOf("PolloGigante").Boss, "Cósimo y Petra son jefes")
check(EnemyStats.hitsToDown(50, EnemyStats.Sources.Attack) == 2 and EnemyStats.hitsToDown(75, EnemyStats.Sources.Attack) == 3, "Con el botón de atacar, el combate dura lo mismo que antes (2 y 3 globos)")
local dealt, immune = EnemyStats.damageFrom("Toy", 0, "PistolaAgua", EnemyStats.toyHurts({ Npc = "Cucaracha1" }))
check(dealt == EnemyStats.ToyDamage.PistolaAgua and not immune, "La pistola de agua sí le hace daño a una cucaracha")
dealt, immune = EnemyStats.damageFrom("Toy", 0, "PistolaAgua", EnemyStats.toyHurts({ Npc = "RobotSeguridad" }))
check(dealt == EnemyStats.ToyWeakDamage.PistolaAgua and dealt > 0 and dealt <= 4 and not immune, "…y a un robot, muy poco (" .. dealt .. "), pero algo: nadie es inmune")
check(EnemyStats.damageFrom("Toy", 0, "Paintball", EnemyStats.toyHurts({ Npc = "Cosimo" })) == EnemyStats.ToyWeakDamage.Paintball, "el paintball contra un jefe: " .. EnemyStats.ToyWeakDamage.Paintball)
local mult = EnemyStats.FirearmMultiplier
check(EnemyStats.damageFrom("Bullet", 24, "Pistola", false) == math.floor(24 * mult + 0.5), ("Una bala de arma de fuego contra un enemigo de misión: su daño × %.1f (24 -> %d)"):format(mult, math.floor(24 * mult + 0.5)))
local pistolShot = EnemyStats.damageFrom("Bullet", Weapons.damageAt(pistol, 10, "Torso"), "Pistola", true)
check(EnemyStats.hitsToDown(50, pistolShot) == 1 and EnemyStats.hitsToDown(75, pistolShot) == 2, "La pistola tumba una cucaracha de 1-2 tiros")
local shell = EnemyStats.damageFrom("Bullet", Weapons.damageAt(Weapons.get("Escopeta"), 5, "Torso") * Weapons.get("Escopeta").Pellets, "Escopeta", false)
local rifle = EnemyStats.damageFrom("Bullet", Weapons.damageAt(Weapons.get("Fusil"), 20, "Torso"), "Fusil", false)
local bossHp = EnemyStats.maxHealth({ Npc = "Cosimo", HP = 10 }, nil)
check(EnemyStats.hitsToDown(bossHp, shell) <= 2 and EnemyStats.hitsToDown(bossHp, rifle) <= 4, ("Un jefe de %d: 2 cartuchos de escopeta (%d) o 4 balas de fusil (%d)"):format(bossHp, shell, rifle))
check(EnemyStats.hitsToDown(bossHp, EnemyStats.Sources.Attack) == 10 and EnemyStats.hitsToDown(bossHp, EnemyStats.Sources.Attack) > EnemyStats.hitsToDown(bossHp, pistolShot), "Sin arma, el botón de atacar también lo acaba (más lento: 10 golpes)")
check(Weapons.damageAt(pistol, 10, "Torso") == 24, "Entre jugadores, la pistola sigue haciendo lo de siempre (24)")
check(EnemyStats.damageFrom("Melee", nil, nil, true) == EnemyStats.Sources.Melee and EnemyStats.damageFrom("Stone", nil, nil, true) == EnemyStats.Sources.Stone, "Golpes y piedras: su propio daño (datos)")
check(EnemyStats.damageFrom("Bullet", 1e9, nil, true) == EnemyStats.MaxPerHit, "Ningún impacto quita más del tope")
local hp, down = EnemyStats.apply(30, 24)
check(hp == 6 and not down, "Quitar vida: 30 - 24 = 6")
hp, down = EnemyStats.apply(6, 24)
check(hp == 0 and down, "Al llegar a 0, cae (nunca vida negativa)")
check(EnemyStats.damageToPlayer({ Npc = "Cucaracha1" }) < EnemyStats.damageToPlayer({ Npc = "PolloGigante" }), "Te quita más una gallina gigante que una cucaracha")
local g, grouped = EnemyStats.group(nil, 10, false, 1)
g, grouped = EnemyStats.group(g, 10, true, 1.2)
check(grouped and g.Amount == 20 and g.Head, "Números de daño muy seguidos: se agrupan (y si alguno fue en la cabeza, amarillo)")
local _, separate = EnemyStats.group(g, 10, false, 2)
check(not separate, "…y si pasa un rato, número nuevo")
check(EnemyStats.showBar(5, nil, 40, 50) and EnemyStats.showBar(200, 1, 40, 50) and not EnemyStats.showBar(200, nil, 40, 50) and not EnemyStats.showBar(5, nil, 0, 50), "La barra se ve si está cerca o le acabas de dar (no si ha caído)")

---------------------------------------------------------------------
-- El servidor de verdad (CombatService, WeaponService, DamageService) en el Roblox de mentira
local okServer, serverError = pcall(function()
	local H = require("./lib/CrimeHarness")
	H.boot()
	local S = "src/server/Services/"
	local Damage = H.load(S .. "DamageService")
	Damage.init()
	local ES = H.load("src/shared/EnemyStats")
	local W = H.Weapons

	-- La misión (en el juego: LifeStoryService.enemyHit) lleva la vida en los atributos
	Damage.enemyHit = function(_attacker, model, kind, amount, info)
		local max = model:GetAttribute("EnemyMaxHealth")
		local before = model:GetAttribute("EnemyHealth")
		local n, imm = ES.damageFrom(kind, amount, info and info.Weapon, ES.toyHurts({ Npc = model:GetAttribute("NpcId") }))
		if n <= 0 then
			return true, 0, before, max, false, imm
		end
		local after, fell = ES.apply(before, n)
		model:SetAttribute("EnemyHealth", after)
		if fell then
			model:SetAttribute("EnemyDown", true)
		end
		return true, n, after, max, fell, false
	end
	local function enemy(npc: string, owner: number, position: Vector3, max: number)
		return H.npc(npc, position, { MissionEnemy = "Prueba", Owner = owner, NpcId = npc, EnemyMaxHealth = max, EnemyHealth = max })
	end
	local function lastDamage(player, from: number)
		local found = nil
		for i = from + 1, #H.sent do
			local m = H.sent[i]
			if m.Remote == "Damage" and m.Player == player then
				found = m.Payload
			end
		end
		return found
	end

	print("\n▶ Cada bala resta el daño correcto (WeaponService.fire -> CombatService -> DamageService)")
	local shooter = H.player("Tiradora", 1001, "Adulto", V(0, 0, 0))
	H.licence(shooter)
	H.give(shooter, "Pistola")
	check(H.WeaponService.equip(shooter, "Pistola"), "empuña la pistola")
	local bug = enemy("Cucaracha1", 1001, V(0, 0, -20), 75)
	local torso = bug:FindFirstChild("UpperTorso")
	local base = W.damageAt(W.get("Pistola"), (torso.Position - V(0, 1.5, 0)).Magnitude, "Torso")
	local expected = math.floor(base * ES.FirearmMultiplier + 0.5)
	local mark = #H.sent
	H.shoot(shooter, bug)
	check(bug:GetAttribute("EnemyHealth") == 75 - expected, ("un disparo al cuerpo: %d × %.1f = %d; 75 - %d = %d"):format(base, ES.FirearmMultiplier, expected, expected, 75 - expected))
	local msg = lastDamage(shooter, mark)
	check(msg ~= nil and msg.Amount == expected and msg.Target == bug and msg.Max == 75, "el cliente que dispara recibe el número de daño y la vida (remoto Damage)")
	H.shoot(shooter, bug)
	check(bug:GetAttribute("EnemyHealth") == 0 and bug:GetAttribute("EnemyDown") == true, "al segundo tiro llega a 0 y cae")
	mark = #H.sent
	H.shoot(shooter, bug)
	check(bug:GetAttribute("EnemyHealth") == 0 and lastDamage(shooter, mark) == nil, "caído, ya no recibe más daño")

	print("\n▶ Cabeza, miembros y distancia (DamageService.apply con la pieza que toca)")
	local boss = enemy("Cosimo", 1001, V(0, 0, -10), 400)
	local r = Damage.apply(shooter, boss, W.damageAt(W.get("Pistola"), 10, "Head"), "Bullet", boss:FindFirstChild("Head"), { Weapon = "Pistola" })
	check(r.Hit and r.Amount == 120 and boss:GetAttribute("EnemyHealth") == 280, "en la cabeza: 120 (24 × 2 × 2,5)")
	r = Damage.apply(shooter, boss, W.damageAt(W.get("Pistola"), 10, "Limb"), "Bullet", nil, { Weapon = "Pistola", Zone = "Limb" })
	check(r.Amount == 45, "en una pierna: 45 (18 × 2,5)")
	r = Damage.apply(shooter, boss, W.damageAt(W.get("Pistola"), 200, "Torso"), "Bullet", nil, { Weapon = "Pistola" })
	check(r.Amount > 0 and r.Amount < 60, ("de lejos (200 studs): %d (menos que 60 de cerca)"):format(r.Amount))
	local before = boss:GetAttribute("EnemyHealth")
	r = Damage.apply(shooter, boss, nil, "Melee")
	check(r.Amount == ES.Sources.Melee and boss:GetAttribute("EnemyHealth") == before - ES.Sources.Melee, "un puñetazo: " .. ES.Sources.Melee)
	r = Damage.apply(shooter, boss, nil, "Stone")
	check(r.Amount == ES.Sources.Stone, "una pedrada: " .. ES.Sources.Stone)

	print("\n▶ Juguetes: la pistola de agua contra una cucaracha (su daño) y contra un robot (muy poco)")
	local kid = H.player("Peque", 1002, "Nino", V(50, 0, 0))
	H.give(kid, "PistolaAgua")
	check(H.WeaponService.equip(kid, "PistolaAgua"), "empuña la pistola de agua")
	local roach = enemy("Cucaracha2", 1002, V(50, 0, -12), 50)
	H.shoot(kid, roach)
	check(roach:GetAttribute("EnemyHealth") == 50 - ES.ToyDamage.PistolaAgua, "a la cucaracha le quita " .. ES.ToyDamage.PistolaAgua)
	local robot = enemy("RobotSeguridad", 1002, V(50, 0, -14), 125)
	mark = #H.sent
	H.shoot(kid, robot)
	local weakMsg = lastDamage(kid, mark)
	check(robot:GetAttribute("EnemyHealth") == 125 - ES.ToyWeakDamage.PistolaAgua and weakMsg ~= nil and weakMsg.Amount == ES.ToyWeakDamage.PistolaAgua and weakMsg.Immune == nil, "al robot le quita muy poco (" .. ES.ToyWeakDamage.PistolaAgua .. "), sin «Inmune»")

	print("\n▶ Solo el servidor aplica daño")
	local other = enemy("Cucaracha3", 9999, V(0, 0, -25), 75)
	H.shoot(shooter, other)
	check(other:GetAttribute("EnemyHealth") == 75, "el enemigo de otro jugador no recibe tus balas")
	local fake = H.remotes.Damage
	local okFake = pcall(function()
		fake.OnServerEvent:Fire(shooter, "Damage", boss, 999)
		fake.OnServerEvent:Fire(shooter, boss, 999, "Bullet")
	end)
	check(okFake and boss:GetAttribute("EnemyHealth") == before - ES.Sources.Melee - ES.Sources.Stone, "lo que mande el cliente por el remoto Damage no hace nada")
	local damageSource = fs.readFile("src/server/Services/DamageService.luau")
	check(string.find(damageSource, "OnServerEvent", 1, true) == nil or string.find(damageSource, "OnServerEvent:Connect", 1, true) == nil, "DamageService no escucha al cliente")
	r = Damage.apply(shooter, boss, 1e9, "Bullet")
	check(r.Amount == ES.MaxPerHit, "un daño exagerado se queda en el tope (" .. ES.MaxPerHit .. ")")
	check(H.WeaponService.fire(shooter, "no es un punto") == false, "disparar manda solo un punto: el daño lo calcula el servidor")

	print("\n▶ Caer en combate (jugador)")
	local fallenHook = nil
	Damage.playerFell = function(player)
		fallenHook = player
	end
	local victim = H.player("Victima", 1003, "Nino", V(100, 0, 0))
	local hum = victim.Character:FindFirstChildOfClass("Humanoid")
	check(Damage.hurtPlayer(victim, 30) == false and hum.Health == 70, "un enemigo te quita vida: 100 - 30 = 70 (la barra ❤️ del HUD baja con Humanoid.Health)")
	check(Damage.hurtPlayer(victim, 500) == true and hum.Health == 1, "sin vida, caes (no mueres: te quedas con 1)")
	task.wait(0.05)
	check(victim:GetAttribute("Fallen") == "Mission" and victim:GetAttribute("KO") == true and fallenHook == victim, "caído en combate (Fallen = Mission, en el suelo): la misión se entera")
	check(Damage.hurtPlayer(victim, 10) == false and hum.Health == 1, "caído, no te siguen quitando vida")
	Damage.getUp(victim, true)
	check(hum.Health == 100 and victim:GetAttribute("Fallen") == nil and victim:GetAttribute("KO") == nil, "al reintentar te levantas con la vida entera")

	-- En una pelea (otro jugador): K.O. con la pantalla de caído en combate
	local rival = H.player("Rival", 1004, "Adulto", V(0, 0, -15))
	local rivalHum = rival.Character:FindFirstChildOfClass("Humanoid")
	rivalHum.Health = 5
	H.shoot(shooter, rival.Character)
	check(rival:GetAttribute("KO") == true and rival:GetAttribute("Fallen") == "Combat" and rivalHum.Health > 0, "en una pelea, sin vida: K.O. en el suelo y «HAS CAÍDO EN COMBATE»")
	-- Otro, K.O. a la vez, al que detiene la policía mientras está en el suelo
	local caught = H.player("Detenido", 1005, "Adulto", V(3, 0, -15))
	local caughtHum = caught.Character:FindFirstChildOfClass("Humanoid")
	caughtHum.Health = 5
	H.shoot(shooter, caught.Character)
	check(caught:GetAttribute("Fallen") == "Combat", "(otro jugador K.O.)")
	H.load("src/server/LifeStory/StoryEvents").emit(caught, "Arrested", { Stars = 2 })
	task.wait(H.load("src/shared/Combat").KOSeconds + 0.5)
	check(rivalHum.Health == 0 and rival:GetAttribute("Fallen") == nil, "a los segundos en el suelo, SIEMPRE al hospital (muere: HospitalService)")
	check(caughtHum.Health > 0 and caught:GetAttribute("KO") == nil, "…salvo si la policía te ha detenido estando K.O.: vas detenido, no al hospital")
end)
check(okServer, "las pruebas del servidor terminan sin errores" .. (if okServer then "" else ": " .. tostring(serverError)))

---------------------------------------------------------------------
-- La misión de verdad (LifeStoryService) con el doble de la historia: las cucarachas de Bigotes
local okStory, storyError = pcall(function()
	local SH = require("./lib/StoryHarness")
	local Service = SH.boot()
	local ROOT = SH.ROOT
	local ES = SH.loadModule(ROOT .. "/shared/EnemyStats")
	ES.PlayerFallSeconds = 0.4 -- (en la prueba no se esperan 6 s en el suelo)
	local Damage = SH.loadModule(ROOT .. "/server/Services/DamageService")
	local profiles = SH.profiles
	local quest = "Loco_N2_Bigotes"

	print("\n▶ Misión: las cucarachas de Bigotes con vida por puntos")
	local kiko = SH.newPlayer("Kiko", "Nino")
	local story = profiles[kiko].Story
	story.Completed.Loco_N1_Cosme = os.time()
	local hum = { Health = 100, MaxHealth = 100 }
	kiko.Character = {
		FindFirstChildOfClass = function(_, class)
			return if class == "Humanoid" then hum else nil
		end,
		FindFirstChild = function()
			return nil
		end,
	}
	local function fakeEnemy(npc: string)
		local attrs = { MissionEnemy = quest, NpcId = npc, Owner = kiko.UserId }
		return {
			GetAttribute = function(_, key)
				return attrs[key]
			end,
			SetAttribute = function(_, key, value)
				attrs[key] = value
			end,
		}
	end

	local results: { [string]: any } = {}
	SH.Service.observe(function(kind, who, questId, info)
		if who ~= kiko or questId ~= quest then
			return
		end
		if kind == "StepEnter" and info and info.Type == "Fight" and not results.Entered then
			results.Entered = true
			task.defer(function()
				local prog = story.Active[quest]
				local hitsBefore = kiko.Hits or 0
				Service.interact(kiko, "Actor", quest, "Cucaracha1")
				results.AfterStrike = prog.Hp and prog.Hp.Cucaracha1
				results.StrikeHits = (kiko.Hits or 0) - hitsBefore
				local okHit, counted, dealtHead = pcall(Service.enemyHit, kiko, fakeEnemy("Cucaracha3"), "Bullet", 24, { Zone = "Torso", Weapon = "Pistola" })
				results.Bullet = okHit and counted and dealtHead
				results.AfterBullet = prog.Hp and prog.Hp.Cucaracha3
				Service.enemyHit(kiko, fakeEnemy("Cucaracha3"), "Toy", 0, { Weapon = "PistolaAgua" })
				results.AfterToy = prog.Hp and prog.Hp.Cucaracha3
				-- Te quedas sin vida en el combate
				results.Fell = Damage.hurtPlayer(kiko, 500)
				results.FallenAttr = kiko:GetAttribute("Fallen")
				Service.interact(kiko, "Actor", quest, "Cucaracha1")
				results.WhileFallen = prog.Hp and prog.Hp.Cucaracha1
			end)
		elseif kind == "FightRetry" then
			local prog = story.Active[quest]
			results.Retry = {
				Hp = prog and prog.Hp and next(prog.Hp) == nil,
				Sub = prog and prog.Sub and next(prog.Sub) == nil,
				Count = prog and prog.Count,
				Retries = prog and prog.Retries,
				Health = hum.Health,
				Fallen = kiko:GetAttribute("Fallen"),
				Step = prog and prog.Step,
				Hits = kiko.Hits or 0,
			}
		end
	end)

	SH.lighting.ClockTime = 12
	for _ = 1, 12 do
		if story.Active[quest] or story.Completed[quest] then
			break
		end
		kiko.At = SH.Quests[quest].Offer.Place
		SH.passTime(kiko, 5)
		if SH.received(kiko, "Offer", SH.Quests[quest].Title) then
			SH.fromClient(kiko, "Offer", quest, true)
		end
	end
	check(story.Active[quest] ~= nil, "Bigotes te pide ayuda (misión aceptada)")
	local done = SH.playQuest(kiko, quest, 200)
	check(results.Entered == true, "llega el combate (paso Fight)")
	check(results.AfterStrike == 25 and results.StrikeHits == 1, "un globo de agua (botón de atacar) quita 25: la cucaracha de «2 golpes» se queda en 25 de 50")
	local shot = math.floor(24 * ES.FirearmMultiplier + 0.5)
	check(results.Bullet == shot and results.AfterBullet == 75 - shot, ("una bala de pistola (%d) a la cucaracha de «3 golpes» (75): le quedan %d"):format(shot, 75 - shot))
	check(results.AfterToy == 75 - shot - ES.ToyDamage.PistolaAgua, "la pistola de agua también le quita (" .. ES.ToyDamage.PistolaAgua .. ")")
	check(results.Fell == true and results.FallenAttr == "Mission", "sin vida en el combate: caes (Fallen = Mission)")
	check(results.WhileFallen == 25, "caído no puedes atacar")
	local retry = results.Retry
	check(retry ~= nil and retry.Hp and retry.Sub and retry.Count == 0 and retry.Retries == 1, "al levantarte, el combate vuelve a empezar desde el principio del paso (enemigos con la vida entera)")
	check(retry ~= nil and retry.Health == 100 and retry.Fallen == nil, "…y tú con la vida entera, de pie")
	check(done and story.Completed[quest] ~= nil and profiles[kiko].Items.CoronaBigotes == 1, "sin perder la misión: al caer las tres cucarachas el paso Fight se completa y la misión acaba")
	check(retry ~= nil and (kiko.Hits or 0) - retry.Hits == 7, "tras reintentar: 2 + 2 + 3 globos, como antes")
	check(Service.enemyHit(kiko, fakeEnemy("Cucaracha1"), "Bullet", 24, {}) == false, "acabado el combate, ya no hay enemigos a los que dañar")
end)
check(okStory, "las pruebas de la misión terminan sin errores" .. (if okStory then "" else ": " .. tostring(storyError)))

---------------------------------------------------------------------
print("\n▶ Cliente: barras de vida, números y borde rojo (Controllers/HealthBars)")
local bars = fs.readFile("src/client/Controllers/HealthBars.luau")
local main = fs.readFile("src/client/Main.client.luau")
local death = fs.readFile("src/client/Controllers/DeathUI.luau")
local story = fs.readFile("src/server/Services/LifeStoryService.luau")
check(string.find(main, "task.spawn(HealthBars.init)", 1, true) ~= nil, "Main.client arranca HealthBars")
check(string.find(bars, "BillboardGui", 1, true) ~= nil and string.find(bars, "EnemyStats.showBar", 1, true) ~= nil and string.find(bars, "mine(item)", 1, true) ~= nil, "barra de vida sobre cada enemigo de tu combate (solo la tuya, si está cerca o le has dado)")
check(string.find(bars, "YELLOW", 1, true) ~= nil and string.find(bars, "EnemyStats.group", 1, true) ~= nil, "números flotantes: amarillos en la cabeza y agrupados")
check(string.find(bars, "Highlight", 1, true) ~= nil and string.find(bars, "HealthChanged", 1, true) ~= nil, "destello en el enemigo y borde rojo en tu pantalla al recibir daño")
check(string.find(bars, "FireServer", 1, true) == nil, "el cliente no manda daño a nadie")
check(string.find(death, "HAS CAÍDO EN COMBATE", 1, true) ~= nil and string.find(death, "\"Fallen\"", 1, true) ~= nil, "DeathUI enseña «HAS CAÍDO EN COMBATE» (atributo Fallen)")
check(string.find(story, "DamageService.hurtPlayer, player, hurt", 1, true) ~= nil, "cuando te atrapa un enemigo de misión, te quita su daño")

print("")
if failures > 0 then
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
process.exit(0) -- (los bucles de los servicios no acaban solos)
