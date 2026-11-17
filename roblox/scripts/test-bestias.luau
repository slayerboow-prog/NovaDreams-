-- test-bestias: las bestias, jefes, guaridas y alijos de los planetas (shared/Cosmos/Bestiary) y el Taller
-- (shared/Crafting; Services/BeastService, Services/CraftingService). lune run scripts/test-bestias.luau

local fs = require("@lune/fs")
local Vector3 = require("@lune/roblox").Vector3
local CFrame = require("@lune/roblox").CFrame
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")
local check = L.check

local Registry = L.load("src/shared/Cosmos/PlanetRegistry")
local Bestiary = L.load("src/shared/Cosmos/Bestiary")
local CityPlanT = L.load("src/shared/CityPlan") -- (los distritos de caza: 17-11-2026)
local Crafting = L.load("src/shared/Crafting")
local Items = L.load("src/shared/Items")

local ORES = Crafting.Ores
local function known(id: string): boolean
	return Items.get(id) ~= nil or ORES[id] == true
end

print("🐺 Bestias de cada planeta")
for _, id in Registry.Order do
	local S = Registry.get(id)
	local list = Bestiary.ByPlanet[id]
	check(list ~= nil and #list == 3 and Bestiary.Species[list.Boss] ~= nil and Bestiary.Species[list.Boss].Boss == true, id .. ": tres bestias y su jefe")
	local dropsOk = true
	for _, sid in list do
		local sp = Bestiary.Species[sid]
		dropsOk = dropsOk and sp.Planet == id and sp.Hp > 0 and sp.Damage > 0
		for _, d in sp.Drops do
			dropsOk = dropsOk and known(d[1]) and d[2] >= 1 and d[3] >= d[2] and d[4] > 0 and d[4] <= 1
		end
	end
	check(dropsOk, id .. ": lo que sueltan existe en la mochila")
	local p = Bestiary.places(S)
	check(#p.Lairs >= 7, ("%s: guaridas por el planeta (%d)"):format(id, #p.Lairs))
	check(p.Boss ~= nil, id .. ": la guarida del jefe escondido")
	check(#p.Caches >= 5, ("%s: alijos escondidos (%d)"):format(id, #p.Caches))
	-- fuera de la ciudad, fuera del agua, lejos de los puntos de interés y repartidas
	local ok, spread = true, true
	local all = table.clone(p.Lairs)
	if p.Boss then
		table.insert(all, p.Boss)
	end
	for _, c in p.Caches do
		table.insert(all, c)
	end
	for i, l in all do
		local M = S.Metro
		if (M and M.lotAt(l.X, l.Z, 20)) or S.City.inside(l.X, l.Z, 30) then
			ok = false
		end
		local _, water = S.groundAt(S.Origin.X + l.X, S.Origin.Z + l.Z)
		if water and not (l.Islet and l.Y >= S.WaterY + 1) then
			ok = false -- (en el agua solo sobre un arrecife: Tálasa)
		end
		for _, poi in S.POIs or {} do
			if math.sqrt((l.X - poi.X) ^ 2 + (l.Z - poi.Z) ^ 2) < (poi.Flat or 0) + 20 then
				ok = false
			end
		end
		for j = i + 1, #all do
			if math.sqrt((l.X - all[j].X) ^ 2 + (l.Z - all[j].Z) ^ 2) < 90 then
				spread = false
			end
		end

	end
	check(ok, id .. ": guaridas y alijos fuera de la ciudad, del agua y de los puntos de interés")
	check(spread, id .. ": repartidos (ninguno pegado a otro)")
	-- zonas de caza: cuatro anillos de manadas, cada vez más lejos y con más nivel
	local perTier, dist = {}, {}
	for _, l in p.Lairs do
		perTier[l.Tier] = (perTier[l.Tier] or 0) + 1
		dist[l.Tier] = (dist[l.Tier] or 0) + math.sqrt(l.X ^ 2 + l.Z ^ 2)
	end
	local zonesOk = #p.Lairs >= 30
	for tier = 1, #Bestiary.Zones do
		zonesOk = zonesOk and (perTier[tier] or 0) >= 6
		if tier > 2 and perTier[tier] and perTier[tier - 1] then
			zonesOk = zonesOk and dist[tier] / perTier[tier] > dist[tier - 1] / perTier[tier - 1]
		end
	end
	check(zonesOk, ("%s: cuatro zonas de caza, más lejos cuanto más nivel (%d manadas)"):format(id, #p.Lairs))
	check(S.Half >= S.CoreHalf + 800, id .. ": tierras salvajes alrededor de la ciudad")
	local shardTiers, shardOk = {}, #p.Shards >= 8
	for _, sh in p.Shards do
		shardTiers[sh.Tier] = (shardTiers[sh.Tier] or 0) + 1
		shardOk = shardOk and Bestiary.Species[sh.Species] ~= nil and not (S.City.inside(sh.X, sh.Z, 30))
	end
	-- tierras salvajes con decorado y senderos
	local T = S.Trails
	local tx, tz = T.point(1, (T.R0 + T.R1) / 2)
	local onTrail = T.at(tx, tz)
	local offTrail = T.at(0, 0)
	local wildN, kinds = 0, 0
	for kind in S.DecorCounts do
		kinds += 1
		for _, d in S.decor(kind, nil, true) do
			local lx, lz = d.Pos.X - S.Origin.X, d.Pos.Z - S.Origin.Z
			if math.max(math.abs(lx), math.abs(lz)) > S.CoreHalf * 0.7 then
				wildN += 1
			end
		end
	end
	check(onTrail and not offTrail and T.R1 > T.R0 + 500, id .. ": cuatro senderos de la ciudad a los confines")
	check(kinds == 0 or Bestiary.WaterLairs[id] or wildN >= 10, ("%s: flora y rocas en las tierras salvajes (%d)"):format(id, wildN))
	check(shardOk and (shardTiers[1] or 0) >= 1 and (shardTiers[4] or 0) >= 2, ("%s: esquirlas de la Grieta en todas las zonas (%d)"):format(id, #p.Shards))
	local again = Bestiary.places(S)
	check(again.Lairs[1].X == p.Lairs[1].X, id .. ": siempre en el mismo sitio")
end

local zOk = #Bestiary.Zones == 4
for i = 2, #Bestiary.Zones do
	local z0, z1 = Bestiary.Zones[i - 1], Bestiary.Zones[i]
	zOk = zOk and z1.Level > z0.Level and z1.Hp > z0.Hp and z1.Damage > z0.Damage and z1.Reward > z0.Reward
end
check(zOk and Bestiary.leveledName("Rondador de ceniza", 2) == "Rondador de ceniza nv. 15" and Bestiary.zone(99).Level == 35, "cada zona pide más y da más; el nombre lleva su nivel")

local sl1 = Bestiary.shardLoot(1, "Tefra", function() return 0.99 end)
local sl4 = Bestiary.shardLoot(4, "Tefra", function() return 0.01 end)
check((sl1.PiedraPulir or 0) >= 3 and (sl4.PiedraPulir or 0) > (sl1.PiedraPulir or 0) - 3 and sl4.PiedraTemple == 1 and sl4.EsenciaEstelar == 1 and (sl4.BrasaViva or 0) >= 1, "las esquirlas rotas dan piedras de mejorar y más cuanto más lejos")
local knownLoot = true
for k in sl4 do
	knownLoot = knownLoot and known(k)
end
check(knownLoot and #Bestiary.Shard.Waves == 3 and #Bestiary.Shard.WaveSize == 3, "lo que dan existe y sueltan tres oleadas")
local BeastKitShard = L.load("src/server/World/Kit/BeastKit")
local okShard, shardModel = pcall(BeastKitShard.shard, CFrame.new(0, 0, 0), 3)
check(okShard and shardModel.PrimaryPart ~= nil and shardModel.PrimaryPart.Anchored and shardModel:FindFirstChildOfClass("Humanoid") ~= nil, "la esquirla se dibuja quieta y con humanoide (los golpes la encuentran) " .. (if okShard then "" else tostring(shardModel)))
local bsSrc = fs.readFile("src/server/Services/BeastService.luau")
check(string.find(bsSrc, "shardWave(b, idx, attacker)", 1, true) ~= nil and string.find(bsSrc, "pcall(manageShards, b.S)", 1, true) ~= nil and string.find(bsSrc, "Bestiary.shardLoot(b.Tier", 1, true) ~= nil, "el servidor saca las esquirlas, suelta las oleadas y reparte su botín")

local BKit = L.load("src/server/World/Kit/BeastKit")
local okSign, sign = pcall(BKit.zoneSign, roblox.Instance.new("Folder"), CFrame.new(0, 0, 0), "Campo abierto · nv. 15", 2)
local okRuin, ruin = pcall(BKit.ruin, roblox.Instance.new("Folder"), CFrame.new(0, 0, 0), "Hielo", 42)
check(okSign and okRuin and #sign:GetChildren() >= 3 and #ruin:GetChildren() >= 5, "carteles de zona y ruinas se dibujan " .. (if okSign then "" else tostring(sign)) .. (if okRuin then "" else tostring(ruin)))
check(string.find(fs.readFile("src/server/World/PlanetWorld.luau"), "S.decor(kind, nil, wild)", 1, true) ~= nil and string.find(fs.readFile("src/server/Services/BeastService.luau"), "BeastKit.zoneSign", 1, true) ~= nil, "el mundo pone el decorado salvaje, los carteles y las ruinas")

print("🎁 Botín")
local function seq(values: { number }): () -> number
	local i = 0
	return function()
		i += 1
		return values[(i - 1) % #values + 1]
	end
end
local loot = Bestiary.loot("Rondador", seq({ 0.1, 0.9, 0.1, 0.1 }))
check((loot.Cuero or 0) == 2 and (loot.Colmillo or 0) == 1, "el botín sale de su tabla (cuero seguro, colmillo a veces)")
local none = Bestiary.loot("Rondador", seq({ 0.1, 0.0, 0.99 }))
check(none.Colmillo == nil, "lo que es a veces, a veces no sale")
local boss = Bestiary.loot("BestiaBrasa", math.random)
check((boss.NucleoBrasa or 0) == 1, "el jefe siempre suelta su trofeo")
local cache, cash = Bestiary.cacheLoot("Siroco", math.random)
local cacheOk = cash >= 40
for k in cache do
	cacheOk = cacheOk and known(k)
end
check(cacheOk, "los alijos dan materiales que existen y algo de dinero")

print("🛠 Recetas")
local recipesOk, outputsOk = true, true
local used: { [string]: boolean } = {}
for _, r in Crafting.Recipes do
	outputsOk = outputsOk and Items.get(r.Id) ~= nil and r.Makes >= 1 and Crafting.Benches[r.Bench] ~= nil and table.find(Crafting.Categories, r.Category) ~= nil
	for k, v in r.Needs do
		recipesOk = recipesOk and known(k) and v >= 1
		used[k] = true
	end
end
check(recipesOk, "todas las recetas piden cosas que existen")
check(outputsOk, "todo lo que se fabrica existe en la mochila, con su banco y su categoría")
local dropsUsed = true
for _, sp in Bestiary.Species do
	for _, d in sp.Drops do
		dropsUsed = dropsUsed and used[d[1]] == true
	end
end
check(dropsUsed, "todo lo que sueltan las bestias (y los trofeos de los jefes) sirve para alguna receta")
local gearMade = true
for _, g in Crafting.Gear do
	gearMade = gearMade and Crafting.recipe(g.Id) ~= nil
end
check(gearMade, "cada arma, armadura, poción y herramienta tiene su receta")
local cats = {}
for _, r in Crafting.Recipes do
	cats[r.Category] = (cats[r.Category] or 0) + 1
end
check((cats.Armas or 0) >= 5 and (cats.Armaduras or 0) >= 5 and (cats.Pociones or 0) >= 5, "armas, armaduras y pociones de sobra")

local have = { Cuero = 11, Colmillo = 3 }
local armor = Crafting.recipe("ArmaduraCuero")
check(Crafting.times(armor, have) == 2 and #Crafting.missing(armor, { Cuero = 2 }) == 1, "cuántas veces se puede fabricar y lo que falta")
check(Crafting.benchHas("Taller", Crafting.recipe("PocionFuerza")) and not Crafting.benchHas("Mesa", Crafting.recipe("PocionFuerza")) and Crafting.benchHas("Mesa", armor), "la mesa plegable solo hace lo de Mesa; el Taller, todo")
local hold = Crafting.have({ Items = { Cuero = 2 }, Space = { Ore = { Hierro = 5 } } })
check(hold.Cuero == 2 and hold.Hierro == 5, "los minerales de la bodega de la nave también cuentan")
check(Crafting.defenseOf({ ArmaduraCuero = 1, ArmaduraEscamas = 1 }) == 0.3 and Crafting.bladeOf({ HachaHueso = 1 }) == 0.45, "vale la mejor armadura y la mejor arma que lleves")
check(Crafting.damageTaken(100, 0.55, 0.25) == 25 and Crafting.damageTaken(10, 0, 0) == 10, "la armadura baja el daño, pero nunca a menos de un 25 %")

print("💎 Materiales, equipo y mejoras")
check(#Crafting.Materials >= 50, ("al menos 50 materiales distintos (%d)"):format(#Crafting.Materials))
local uniqueOk, nUnique = true, 0
for sp, mat in Bestiary.Unique do
	nUnique += 1
	uniqueOk = uniqueOk and Bestiary.Species[sp] ~= nil and Items.get(mat) ~= nil
end
check(uniqueOk and nUnique == 24, "cada bestia normal suelta un material solo suyo")
local slots = {}
for _, g in Crafting.Gear do
	local slot = Crafting.slotOf(g)
	if slot then
		slots[slot] = (slots[slot] or 0) + 1
	end
end
local allSlots = true
for _, slot in Crafting.Slots do
	allSlots = allSlots and (slots[slot] or 0) >= 2
end
check(allSlots, "armas, armadura, casco, escudo, botas, collar, pulsera y pendientes: al menos dos de cada")
local bag = { ArmaduraCuero = 1, ArmaduraEscamas = 1, CascoCeniza = 1, EscudoNacar = 1, HachaHueso = 1, CollarEnjambre = 1, PulseraCobre = 1, PendientesHielo = 1 }
local worn = Crafting.stats(bag, {})
check(math.abs(worn.Defense - 0.41) < 1e-6 and math.abs(worn.Blade - 0.55) < 1e-6 and math.abs(worn.Luck - 0.1) < 1e-6 and worn.Vigor == 12 and worn.Worn.Armadura == "ArmaduraEscamas", "se suma lo mejor de cada hueco")
local up = Crafting.stats(bag, { HachaHueso = 9, ArmaduraCuero = 9 })
check(math.abs(up.Blade - (0.45 * 1.9 + 0.1)) < 1e-6 and up.Worn.Armadura == "ArmaduraEscamas", "un arma +9 pega casi el doble; una armadura floja +9 no gana a una buena")
check(Crafting.stats({ ArmaduraTrofeo = 1, CascoCromo = 1, EscudoCorteza = 1, BotasEscarcha = 1 }, { ArmaduraTrofeo = 9 }).Defense == Crafting.MaxDefense, "la defensa tiene tope")
check(#Crafting.RefineSteps == Crafting.MaxRefine and Crafting.refineStep(9) == nil, "nueve pasos de mejora, de +0 a +9")
local chancesDown, stonesKnown = true, true
for i, st in Crafting.RefineSteps do
	chancesDown = chancesDown and (i == 1 or st.Chance <= Crafting.RefineSteps[i - 1].Chance) and st.Money > 0
	stonesKnown = stonesKnown and Items.get(st.Stone) ~= nil
end
check(chancesDown and stonesKnown, "cada mejora es más difícil y más cara que la anterior")
local l1, o1 = Crafting.refineRoll(0, 0.999, false)
local l2, o2 = Crafting.refineRoll(2, 0.99, false)
local l3, o3 = Crafting.refineRoll(6, 0.99, false)
local l4, o4 = Crafting.refineRoll(6, 0.99, true)
local l5, o5 = Crafting.refineRoll(6, 0.1, false)
check(l1 == 1 and o1 == "Ok", "la primera mejora sale siempre")
check(l2 == 2 and o2 == "Fail", "fallar por debajo de +5 no baja el objeto")
check(l3 == 5 and o3 == "Drop" and l4 == 6 and o4 == "Saved" and l5 == 7 and o5 == "Ok", "de +5 en adelante un fallo baja un nivel, salvo con el Sello del herrero")
check(Crafting.refinedName("Lanza de escama", 3) == "Lanza de escama +3" and Crafting.refinedName("Lanza", 0) == "Lanza", "el nombre lleva su mejora")
check(Crafting.hunterLevel(0) == 1 and Crafting.hunterLevel(50) == 2 and Crafting.hunterLevel(1e9) == Crafting.MaxHunter and Crafting.hunterBonus(200) == 0.04, "el nivel de cazador sube con la experiencia y da daño")
check(Crafting.killXp(160) == 20 and Crafting.killXp(3200, true) == 800, "las bestias duras dan más experiencia; los jefes, el doble")
local lucky, plain = 0, 0
for i = 1, 400 do
	local r1, r2 = Bestiary.rng(i), Bestiary.rng(i)
	plain += Bestiary.loot("Rondador", r1).PelajeCeniza or 0
	lucky += Bestiary.loot("Rondador", r2, 0.5).PelajeCeniza or 0
end
check(plain > 100 and lucky > plain, ("la suerte hace caer más botín raro (%d → %d de 400)"):format(plain, lucky))
check(Crafting.benchHas("Mochila", Crafting.recipe("EspadaTrofeo")), "desde la mochila se fabrica todo, en cualquier sitio")
local craftSrc = fs.readFile("src/server/Services/CraftingService.luau")
check(string.find(craftSrc, 'action == "Refine"', 1, true) ~= nil and string.find(craftSrc, 'action == "OpenBag"', 1, true) ~= nil, "el servidor atiende «mejorar» y «abrir desde la mochila»")
check(string.find(fs.readFile("src/client/Controllers/InventoryUI.luau"), "openFromBag", 1, true) ~= nil, "la mochila tiene su botón de fabricar")

print("🌀 Habilidades de cazador")
local Skills = L.load("src/shared/HunterSkills")
local skOk, lastLevel = #Skills.List >= 6, 0
for _, sk in Skills.List do
	skOk = skOk and sk.Level > lastLevel and sk.Cooldown > 0 and (if sk.Kind == "Buff" then sk.Buff ~= nil else sk.Power > 1) and #sk.Key == 1
	lastLevel = sk.Level
end
check(skOk, "seis habilidades (golpes, armas de fuego y defensa), cada una con más nivel que la anterior")
check(string.find(fs.readFile("src/server/Services/BeastService.luau"), 'buff(attacker, "Punteria")', 1, true) ~= nil and string.find(fs.readFile("src/server/Services/BeastService.luau"), 'buff(player, "Coraza")', 1, true) ~= nil, "la puntería sube los disparos y la coraza baja el daño")
local tajo = Skills.get("TajoCircular")
check(not Skills.unlocked(tajo, 1) and Skills.unlocked(tajo, 2) and Skills.remaining(tajo, nil, 10) == 0 and Skills.remaining(tajo, 10, 13) == 5 and Skills.remaining(tajo, 10, 30) == 0, "se desbloquean por nivel y tienen que esperar para repetirse")
local dashSk = Skills.get("Embestida")
local from, dir = Vector3.new(0, 5, 0), Vector3.new(0, 0, -1)
check(Skills.inDash(dashSk, from, dir, Vector3.new(1, 5, -20)) and not Skills.inDash(dashSk, from, dir, Vector3.new(12, 5, -20)) and not Skills.inDash(dashSk, from, dir, Vector3.new(0, 5, 20)) and not Skills.inDash(dashSk, from, dir, Vector3.new(0, 5, -60)), "la embestida alcanza lo que cruzas, no lo de los lados ni lo de detrás")
local skillSrc = fs.readFile("src/server/Services/HunterSkillService.luau")
check(string.find(skillSrc, "Beasts.near(from, reach)", 1, true) ~= nil and string.find(fs.readFile("src/server/Services/BeastService.luau"), 'buff(attacker, "Furia")', 1, true) ~= nil, "el servidor hace el daño a las bestias cercanas y cuenta la furia")
check(string.find(fs.readFile("src/server/Main.server.luau"), '"HunterSkillService"', 1, true) ~= nil and string.find(fs.readFile("src/client/Main.client.luau"), "HunterSkillsUI", 1, true) ~= nil, "las habilidades están conectadas en el servidor y en el cliente")

print("🗡 Estilos de arma, rangos y equipo visible")
local Combat = L.load("src/shared/Combat")
local stylesOk = true
for id, st in Combat.WeaponOf do
	stylesOk = stylesOk and Crafting.gear(id) ~= nil and Crafting.gear(id).Kind == "Blade" and Combat.WeaponStyles[st] ~= nil
end
check(stylesOk and Combat.styleOfWeapon(nil) == "" and Combat.weaponStyle("").Speed == 1, "cada arma blanca tiene su estilo de golpe; sin arma, puños")
local knife, axe, spear = Combat.WeaponStyles.Cuchillo, Combat.WeaponStyles.Hacha, Combat.WeaponStyles.Lanza
check(knife.Speed < 1 and axe.Speed > 1 and axe.BeastMul > knife.BeastMul and spear.Reach > axe.Reach, "el cuchillo es rápido, el hacha pesa y la lanza llega lejos")
check(Combat.readyMove("L1", 0, 0.16, 1, knife.Speed) and not Combat.readyMove("L1", 0, 0.16, 1, 1) and not Combat.readyMove("L1", 0, 0.22, 1, axe.Speed), "el estilo cambia la pausa entre golpes")
local ranks = { TajoCircular = 4 }
check(Skills.rankOf(ranks, "TajoCircular") == 4 and Skills.rankOf(ranks, "Furia") == 1 and Skills.pointsLeft(10, ranks) == 6 and Skills.pointsLeft(1, nil) == 0, "rangos de habilidad: se gastan los puntos de cazador")
check(Skills.power(tajo, 10) > Skills.power(tajo, 1) * 2 and Skills.cooldown(tajo, 10) < tajo.Cooldown and Skills.rankName(10) == "Maestra", "cada rango pega más y espera menos; rango 10 = Maestra")
check(Crafting.isEquip("Arma_Pistola") and Crafting.isGun("Arma_Fusil") and not Crafting.isGun("LanzaEscama") and math.abs(Crafting.gunBonus({ Arma_Pistola = 5 }, "Pistola") - 0.4) < 1e-6 and Crafting.gunBonus({}, "Pistola") == 0, "las armas de fuego también se mejoran (+8 % por nivel con esa arma)")
local function limb(m, name, size)
	local p = roblox.Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Parent = m
	return p
end
local body = roblox.Instance.new("Model")
for name, size in { Head = Vector3.new(1.2, 1.2, 1.2), UpperTorso = Vector3.new(2, 1.6, 1), RightHand = Vector3.new(0.6, 0.4, 0.6), LeftLowerArm = Vector3.new(0.6, 1, 0.6), RightLowerArm = Vector3.new(0.6, 1, 0.6), LeftFoot = Vector3.new(0.6, 0.4, 1), RightFoot = Vector3.new(0.6, 0.4, 1) } do
	limb(body, name, size)
end
local GearLook = L.load("src/server/World/Kit/GearLook")
local okLook, folder = pcall(GearLook.apply, body, { Arma = "EspadaTrofeo", Armadura = "ArmaduraEscamas", Casco = "CascoCromo", Escudo = "EscudoNacar", Botas = "BotasDuna", Collar = "CollarEnjambre", Pulsera = "PulseraCobre", Pendientes = "PendientesHielo" }, { EspadaTrofeo = 8 })
local glowing, loose = false, false
if okLook then
	for _, d in folder:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			glowing = true
		end
		if d:IsA("BasePart") and (d.CanCollide or not d.Massless) then
			loose = true
		end
	end
end
check(okLook and #folder:GetChildren() >= 15 and glowing and not loose, "el equipo se ve en el personaje (sin chocar ni pesar) y el arma +8 brilla " .. (if okLook then "" else tostring(folder)))
local missing = true
for _, id in { "ArmaduraCuero", "CascoCeniza", "CuchilloColmillo", "PendientesEstelares" } do
	missing = missing and GearLook.Colors[id] ~= nil
end
check(missing, "cada pieza de equipo tiene su color")
check(string.find(fs.readFile("src/server/Services/InventoryService.luau"), "data.Refine[id] = nil", 1, true) ~= nil, "la mejora es de tu copia: si te quedas sin ella, se va")
check(string.find(fs.readFile("src/server/Services/CombatService.luau"), "style.Targets", 1, true) ~= nil and string.find(fs.readFile("src/client/Controllers/CombatController.luau"), "EstiloArma", 1, true) ~= nil, "el servidor y el cliente usan el estilo de arma")
check(string.find(fs.readFile("src/server/Main.server.luau"), '"GearService"', 1, true) ~= nil, "el equipo visible está conectado")

print("🏞 Zonas de caza de Valmar")
do
	local Relief = L.load("src/shared/Relief")
	local VW = L.load("src/server/World/ValmarWilds")
	-- un relieve de mentira: ciudad construida en el centro (|x|,|z| < 1400), campo salvaje alrededor
	local nx, nz, cell = 340, 300, 32
	local minX, minZ = -5440, -4800
	local amp, built = table.create(nx * nz, 0), table.create(nx * nz, 0)
	for j = 0, nz - 1 do
		for i = 0, nx - 1 do
			local x, z = minX + i * cell, minZ + j * cell
			local city = math.abs(x) < 1400 and math.abs(z) < 1400
			amp[j * nx + i + 1] = if city then 0 else 60
			built[j * nx + i + 1] = if city then 1 else 0
		end
	end
	local field = { NX = nx, NZ = nz, MinX = minX, MinZ = minZ, Cell = cell, Step = 5, Amp = amp, Built = built }
	local S = VW.surface(field, function(x, z)
		return Relief.surfaceY(field, x, z), false
	end)
	check(Bestiary.ByPlanet.Valmar ~= nil and Bestiary.Species.CiervoRoto.Boss == true and Bestiary.Rare.Valmar == "CuarzoGrieta", "Valmar tiene sus bestias, su jefe y su material raro")
	check(not S.goodSpot(0, 0, 1, 0) and not S.goodSpot(1450, 0, 1, 0), "ninguna guarida en la ciudad ni pegada a ella")
	-- las ocho regiones (shared/Cosmos/ValmarRegions)
	local VR = L.load("src/shared/Cosmos/ValmarRegions")
	check(S.Regions ~= nil and #VR.List == 8, "Valmar tiene sus ocho regiones de caza")
	local regOk, rareOk = true, true
	for i, reg in VR.List do
		regOk = regOk and #reg.Species >= 5 and Bestiary.Species[reg.Boss] ~= nil and Bestiary.Species[reg.Boss].Boss == true and reg.MaxLevel > reg.MinLevel
		regOk = regOk and reg.Bearing == (i - 1) * 45
		for _, sid in reg.Species do
			local sp = Bestiary.Species[sid]
			regOk = regOk and sp ~= nil and not sp.Boss and sp.Planet == "Valmar"
			local hasRare = false
			for _, d in sp and sp.Drops or {} do
				regOk = regOk and known(d[1])
				hasRare = hasRare or d[1] == reg.Rare
			end
			rareOk = rareOk and (hasRare or sid == "JabaliSierra" or sid == "AvispaGrieta" or sid == "VivoraPenasco")
		end
		rareOk = rareOk and known(reg.Rare)
	end
	check(regOk, "cada región: tres criaturas de Valmar y su jefe, una cada 45 grados, niveles de menos a más")
	check(rareOk, "las criaturas nuevas sueltan el material de su región")
	check(VR.at(0, 0) == nil and VR.at(0, -3000).Id == "MontanasHeladas" and VR.at(-3000, 0).Id == "PantanoMaldito" and VR.at(2100, -2100).Id == "TierrasVolcanicas" and VR.at(-2100, 2100).Id == "BosqueEtereo" and VR.at(3000, 0).Id == "DesiertoDorado",
		"como el mapa definitivo: norte hielo, oeste pantano, noreste volcán, suroeste bosque, este desierto; la ciudad no es región")
	local lo = VR.levelAt(VR.ById.BosqueEtereo, -1131, 1131)
	local hi = VR.levelAt(VR.ById.BosqueEtereo, -7000, 7000)
	check(lo <= 12 and hi >= 28 and hi <= 30, ("el nivel sube hacia la costa (%d → %d)"):format(lo, hi))
	check(VR.rewardFactor(80, 15) < 0.2 and VR.rewardFactor(20, 15) == 1 and VR.danger(VR.ById.TierrasVolcanicas, 10) == "Peligro",
		"quien supera de largo a la bestia saca poco; aviso de peligro a los novatos")
	local k5, k110 = Bestiary.levelScale(5), Bestiary.levelScale(110)
	check(math.abs(k5.Hp - 1) < 1e-6 and k110.Hp > 10 and k110.Damage > 4 and k110.Reward > 10, "a más nivel, más vida, daño y premio")
	local p = Bestiary.places(S)
	local per, bosses, inCity, inSector, levelsOk = {}, {}, false, true, true
	local farm, farmOk, farmCentral = {}, true, false
	for _, l in p.Lairs do
		if type(l.Region) == "string" and l.Region:sub(1, 5) == "Farm_" then
			-- (17-11-2026) guaridas de los distritos de caza de la isla: dentro de su distrito y con su nivel
			local d = CityPlanT.farmAt(l.X, l.Z)
			farm[l.Region] = (farm[l.Region] or 0) + 1
			farmOk = farmOk and d ~= nil and "Farm_" .. d.Id == l.Region and l.Level >= d.Farm.Min and l.Level <= d.Farm.Max
			farmCentral = farmCentral or CityPlanT.isCentral(l.X, l.Z)
			continue
		end
		inCity = inCity or (math.abs(l.X) < 1400 and math.abs(l.Z) < 1400)
		local reg = VR.ById[l.Region]
		inSector = inSector and reg ~= nil and VR.inside(reg, l.X, l.Z, -1)
		levelsOk = levelsOk and reg ~= nil and l.Level >= reg.MinLevel and l.Level <= reg.MaxLevel
		if l.Boss then
			bosses[l.Region] = (bosses[l.Region] or 0) + 1
		else
			per[l.Region] = (per[l.Region] or 0) + 1
		end
	end
	local eachOk, counts = true, {}
	for _, reg in VR.List do
		eachOk = eachOk and (per[reg.Id] or 0) >= 5 and (bosses[reg.Id] or 0) >= 1
		table.insert(counts, ("%d"):format(per[reg.Id] or 0))
	end
	check(not inCity and inSector and levelsOk, "cada guarida en el campo de su región y con un nivel de su franja")
	local farmCount = 0
	for _ in farm do
		farmCount += 1
	end
	check(farmCount == 4 and farmOk and not farmCentral, ("los cuatro distritos de caza tienen guaridas de su nivel y el Distrito Central ninguna (%d distritos: %d, %d, %d y %d guaridas)"):format(farmCount, farm.Farm_Oeste or 0, farm.Farm_Sur or 0, farm.Farm_Este or 0, farm.Farm_Universitario or 0))
	local outerN = 0
	for _, l in p.Lairs do
		if VR.outside(l.X, l.Z) > 0 then
			outerN += 1
		end
	end
	check(outerN >= 60, ("casi todas las guaridas, al otro lado del mar (%d en las Tierras Exteriores)"):format(outerN))
	check(eachOk and #p.Bosses >= 9 and #p.Shards >= 12 and #p.Caches >= 6,
		("guaridas y jefe en cada región (%s), %d jefes, %d esquirlas, %d alijos"):format(table.concat(counts, "/"), #p.Bosses, #p.Shards, #p.Caches))
	-- las áreas jugables de cada región (shared/Cosmos/RegionGuide): guaridas en cada lugar y el jefe en el suyo
	do
		local RG = L.load("src/shared/Cosmos/RegionGuide")
		local placesOk, bossOk, nPlaces = true, true, 0
		for _, e in RG.all() do
			if e.Place.Level and e.Place.Kind ~= "Santuario" then
				nPlaces += 1
				local found = 0
				for _, l in p.Lairs do
					if l.Place == e.Place.Name and l.Region == e.Region and math.abs(l.Level - e.Place.Level) <= 4 then
						found += 1
					end
				end
				placesOk = placesOk and found >= 2
			end
			if e.Place.Boss then
				local near = false
				for _, b in p.Bosses do
					if b.Region == e.Region and not b.Id:find("_Elite$") and math.sqrt((b.X - e.X) ^ 2 + (b.Z - e.Z) ^ 2) < 140 then
						near = true
					end
				end
				bossOk = bossOk and near
			end
		end
		check(placesOk and nPlaces >= 40, ("cada lugar de cada región tiene sus guaridas de su nivel (%d lugares)"):format(nPlaces))
		check(bossOk, "el jefe de cada región vive en su lugar (el Guardián Ancestral, junto al Árbol Ancestral…)")
	end
	local z = Bestiary.lairZone(p.Lairs[#p.Lairs])
	check(z.Level == p.Lairs[#p.Lairs].Level and z.Name ~= nil and z.Hp >= 1, "la zona de una guarida de región lleva su nivel y su nombre")
	-- los nuevos sitios en el mapa
	local MapInfo = L.load("src/shared/MapInfo")
	local MapLegend = L.load("src/shared/MapLegend")
	local mapOk = true
	for _, reg in VR.List do
		mapOk = mapOk and MapInfo.KindByModel["Region_" .. reg.Id] ~= nil and MapInfo.KindByModel["Jefe_" .. reg.Id] ~= nil
			and MapLegend.categoryOf("Region_" .. reg.Id) ~= nil
	end
	check(mapOk, "cada región y su jefe salen en el mapa y en su leyenda")
	-- el suelo de cada región
	check(Relief.material(40, 0.1, 3600, 0, nil, 1) == "Sand" or Relief.material(40, 0.1, 3600, 40, nil, 1) == "Sand" or Relief.material(40, 0.1, 3640, -20, nil, 1) == "Sand",
		"arena en el Desierto Devastado")
	check(Relief.material(40, 0.1, 100, 100, nil, 1) ~= "Sand" and Relief.material(40, 0.1, 3600, 0, nil, 0) ~= "Sand", "en la ciudad y junto a lo construido, el suelo de siempre")
end

print("🔌 Conexiones")
local combat = fs.readFile("src/server/Services/CombatService.luau")
check(string.find(combat, "CombatService.beastHit", 1, true) ~= nil and string.find(combat, "local hook = targetHook(model)", 1, true) ~= nil, "los golpes y las balas a una bestia van a BeastService")
check(string.find(combat, "GetAttribute(\"Bestia\") == nil", 1, true) ~= nil, "las bestias no se quitan de la lista de golpes (la invasión va aparte)")
local damage = fs.readFile("src/server/Services/DamageService.luau")
check(string.find(damage, "cs.beastHit", 1, true) ~= nil, "y el daño genérico, también")
local main = fs.readFile("src/server/Main.server.luau")
check(string.find(main, "\"BeastService\"", 1, true) ~= nil and string.find(main, "\"CraftingService\"", 1, true) ~= nil, "los servicios arrancan")
local client = fs.readFile("src/client/Main.client.luau")
check(string.find(client, "Controllers.CraftingUI", 1, true) ~= nil, "la ventana del Taller arranca")
local world = fs.readFile("src/server/World/PlanetWorld.luau")
check(string.find(world, "BeastService.buildWilds(S, folder)", 1, true) ~= nil, "PlanetWorld pone guaridas, jefe y alijos")
local metro = fs.readFile("src/server/World/PlanetMetroBuilder.luau")
check(string.find(metro, "BeastKit.bench(", 1, true) ~= nil, "cada distrito de las ciudades tiene su Taller")
local beast = fs.readFile("src/server/Services/BeastService.luau")
check(string.find(beast, "Crafting.damageTaken", 1, true) ~= nil and string.find(beast, "Crafting.bladeOf", 1, true) ~= nil, "la armadura y las armas blancas cuentan contra las bestias")

-- sin emoji modernos (en Roblox salen como ▯)
local modern = { "🫧", "🪢", "🦭", "🪶", "🪨", "🪵", "🪸", "🪲", "🪳", "🫀", "🪤", "🪖", "🪃", "🛖", "🪦", "🪱" }
local bad = {}
for _, f in { "src/shared/Crafting.luau", "src/shared/Cosmos/Bestiary.luau", "src/client/Controllers/CraftingUI.luau", "src/server/World/Kit/BeastKit.luau" } do
	local txt = fs.readFile(f)
	for _, e in modern do
		if string.find(txt, e, 1, true) then
			table.insert(bad, f .. " " .. e)
		end
	end
end
check(#bad == 0, "sin emoji modernos " .. table.concat(bad, ", "))

L.finish("test-bestias")
