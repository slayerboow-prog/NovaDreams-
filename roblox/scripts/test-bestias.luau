-- test-bestias: las bestias, jefes, guaridas y alijos de los planetas (shared/Cosmos/Bestiary) y el Taller
-- (shared/Crafting; Services/BeastService, Services/CraftingService). lune run scripts/test-bestias.luau

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local check = L.check

local Registry = L.load("src/shared/Cosmos/PlanetRegistry")
local Bestiary = L.load("src/shared/Cosmos/Bestiary")
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
	local again = Bestiary.places(S)
	check(again.Lairs[1].X == p.Lairs[1].X, id .. ": siempre en el mismo sitio")
end

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
