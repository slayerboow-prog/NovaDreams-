-- Comprueba las reglas del campo (src/shared/Farming.luau) y de los negocios (src/shared/Business.luau).
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-economy.luau

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

-- Cargador mínimo: script.Parent.X y require como en Roblox (solo para src/shared)
local cache = {}
local nodeMeta = {}
local function node(path: string)
	return setmetatable({ __path = path }, nodeMeta)
end
nodeMeta.__index = function(self, key)
	local path = rawget(self, "__path")
	if key == "Parent" then
		return node((path:match("^(.*)/[^/]+$")))
	end
	return node(path .. "/" .. key)
end
local function load(path: string): any
	if cache[path] then
		return cache[path]
	end
	local env = setmetatable({
		script = node(path),
		require = function(target)
			return load(rawget(target, "__path"))
		end,
		Color3 = roblox.Color3,
		Vector3 = roblox.Vector3,
	}, { __index = _G })
	local result = luau.load(fs.readFile(path .. ".luau"), { debugName = path, environment = env })()
	cache[path] = result
	return result
end

local Farming = load("src/shared/Farming")
local Business = load("src/shared/Business")
local Items = nil
pcall(function()
	Items = load("src/shared/Items")
end)

local failures = 0
local function check(condition: any, message: string)
	if condition then
		print("  ✅ " .. message)
	else
		failures += 1
		print("  ❌ " .. message)
	end
end

print("▶ Cultivos")
local t0 = 1000
local plot = Farming.plant("Tomate", t0)
check(Farming.plotPhase(plot, t0) == "Growing" and Farming.plotPhase(nil, t0) == "Empty", "recién plantado está creciendo; sin nada, vacío")
check(Farming.plotPhase(plot, t0 + Farming.cropById.Tomate.Grow) == "Ready", "cuando pasa su tiempo, está listo")
local ready = plot.ReadyAt
check(Farming.water(plot, t0) and plot.ReadyAt < ready and not Farming.water(plot, t0), "regar acelera, y solo una vez")
check(math.abs((plot.ReadyAt - t0) - math.ceil(Farming.cropById.Tomate.Grow * Farming.WaterFactor)) <= 1, "regado al principio tarda un 30 % menos")
local amount, rest = Farming.harvest(plot, plot.ReadyAt, 0)
check(amount == Farming.cropById.Tomate.Yield[1] + 1 and rest == nil, "cosechar da lo mínimo (+1 por regar) y deja el bancal vacío")
local high = Farming.harvest(Farming.plant("Tomate", 0), 1e6, 0.9999)
check(high == Farming.cropById.Tomate.Yield[2], "con suerte da lo máximo, nunca más")
local tree = Farming.plant("Manzano", 0)
local _, again = Farming.harvest(tree, tree.ReadyAt, 0.5)
check(again ~= nil and again.Crop == "Manzano" and again.ReadyAt == tree.ReadyAt + Farming.cropById.Manzano.Regrow, "los árboles vuelven a dar fruto sin replantar")
check(Farming.growth(plot, t0) == 0 and Farming.growth(plot, plot.ReadyAt + 5) == 1, "el crecimiento va de 0 a 1")

print("▶ Niveles")
check(Farming.levelFor(0) == 1 and Farming.levelFor(Farming.xpFor(5)) == 5 and Farming.levelFor(Farming.xpFor(5) - 1) == 4, "la experiencia marca el nivel")
check(Farming.corralSize(1) == 4 and Farming.corralSize(40) == 10, "el corral crece con el nivel (4 a 10)")
local firstCrops = 0
for _, c in Farming.Crops do
	if c.Level == 1 then
		firstCrops += 1
	end
end
check(firstCrops >= 3 and Farming.animalById.Gallina.Level == 1, "desde el principio hay varios cultivos y gallinas")

print("▶ Productos, semillas y recetas")
local allOk = true
for _, c in Farming.Crops do
	local p = Farming.Products[c.Product]
	if not p then
		allOk = false
		print("    sin producto: " .. c.Id)
	else
		-- Una cosecha media tiene que valer bastante más que la semilla (un árbol, en 4 cosechas)
		local avg = (c.Yield[1] + c.Yield[2]) / 2
		local value = avg * p.Price * (if c.Tree then 4 else 1)
		if value < c.Seed * (if c.Tree then 1.2 else 3) then
			allOk = false
			print("    no compensa plantar: " .. c.Id)
		end
	end
end
check(allOk, "cada cultivo da un producto y plantarlo compensa")
local animalsOk = true
for _, a in Farming.Animals do
	animalsOk = animalsOk and Farming.Products[a.Product] ~= nil and a.Yield * Farming.Products[a.Product].Price > Farming.FeedPrice
end
check(animalsOk, "cada animal da un producto que vale más que el pienso")
local recipesOk = true
for _, r in Farming.Recipes do
	local cost = 0
	for id, n in r.Inputs do
		local p = Farming.Products[id]
		if p then
			cost += p.Price * n
		elseif id == "CafeMolido" then
			cost += 4 * n
		else
			recipesOk = false
			print("    ingrediente desconocido: " .. id .. " en " .. r.Id)
		end
	end
	local value = Farming.Products[r.Output].Price * r.Count
	if value < cost then
		recipesOk = false
		print(("    %s vale menos que sus ingredientes (%d < %d)"):format(r.Id, value, cost))
	end
end
check(recipesOk, "las recetas usan ingredientes que existen y lo fabricado vale más")
local have = { Agro_Trigo = 7 }
check(Farming.canMake(Farming.recipeById.Harina, function(id)
	return have[id] or 0
end) == 2, "con 7 de trigo se hacen 2 sacos de harina")
check(Farming.recipeById.CafeLeche.Inputs.CafeMolido == 1, "el café con leche usa café molido del supermercado")
check(Farming.sellPrice("Agro_Queso", "Super") > Farming.sellPrice("Agro_Queso", "Coop"), "el supermercado paga más que la cooperativa")
check(Farming.cropOfSeed("Semilla_Maiz") == Farming.cropById.Maiz and Farming.cropOfSeed("Pan") == nil, "las semillas se reconocen por su nombre")
if Items then
	check(Items.get("Agro_Tomate") ~= nil and Items.get("Agro_Tomate").Kind == "Food" and Items.get("Agro_Lana").Kind == "Thing", "lo del campo va a la mochila (lo que se come es comida)")
	check(Items.get("Semilla_Olivo") ~= nil and Items.get(Farming.Feed) ~= nil, "semillas, plantones y pienso son objetos de la mochila")
end

print("▶ Locales y tipos de negocio")
local p1 = Business.premisePrice("Local", "L:abc")
check(p1 == Business.premisePrice("Local", "L:abc") and p1 >= 2500 * 0.85 and p1 <= 2500 * 1.16, "el mismo local siempre cuesta lo mismo, alrededor de su precio")
check(Business.premisePrice("Hotel", "H:1") > Business.premisePrice("Gas", "G:1"), "un hotel cuesta más que una gasolinera")
check(#Business.typesFor("Local") == 6 and #Business.typesFor("Gas") == 1 and #Business.typesFor("Hotel") == 1, "6 negocios en locales, más gasolinera y hotel")
check(Business.canSell(Business.Types.Fruteria, "Agro_Manzana") and not Business.canSell(Business.Types.Fruteria, "Agro_Pizza"), "una frutería vende fruta, no pizzas")
check(Business.canSell(Business.Types.Restaurante, "Agro_Pizza") and Business.canSell(Business.Types.Gasolinera, "W_Gasolina"), "el restaurante vende platos y la gasolinera gasolina")
check(Business.nameFor(Business.Types.Panaderia, 1, "Ana") == "Horno Ana" and Business.nameFor(Business.Types.Panaderia, 5, "Ana") == "Horno Ana", "los nombres llevan el nombre del dueño y dan la vuelta")
local gas = Business.Goods.W_Gasolina
check(Business.clampPrice(gas, 1.73) == 1.7 and Business.clampPrice(gas, 99) <= gas.Ref * 3, "el precio de la gasolina va de 10 en 10 céntimos y tiene tope")
check(#Business.wholesaleFor(Business.Types.Gasolinera) >= 3 and #Business.wholesaleFor(Business.Types.Ropa) == 0, "el mayorista sirve gasolina y bebidas, no ropa")

print("▶ Clientes de los vecinos")
local rec = Business.newRecord("L:x", "Local", "Local de prueba", 1, "Ana", 2500, 0)
rec.Type = "Fruteria"
rec.Open = true
rec.Stock = { Agro_Manzana = 200, Agro_Tomate = 200 }
local units, money = Business.simulate(rec, 3600)
check(units > 0 and money > 0 and rec.Till > 0, ("en una hora se venden productos (%d, $%d)"):format(units, money))
check(rec.Stock.Agro_Manzana < 200 and rec.LastSim == 3600, "las existencias bajan")
local units2 = Business.simulate(rec, 3600)
check(units2 == 0, "sin tiempo no se vende nada más (no se cuenta dos veces)")
local cheap = Business.newRecord("L:y", "Local", "t", 1, "Ana", 1, 0)
cheap.Type, cheap.Open = "Fruteria", true
cheap.Stock = { Agro_Manzana = 500 }
cheap.Prices = { Agro_Manzana = Business.Goods.Agro_Manzana.Ref * 0.6 }
local dear = Business.newRecord("L:z", "Local", "t", 1, "Ana", 1, 0)
dear.Type, dear.Open = "Fruteria", true
dear.Stock = { Agro_Manzana = 500 }
dear.Prices = { Agro_Manzana = Business.Goods.Agro_Manzana.Ref * 1.6 }
local uc = Business.simulate(cheap, 7200)
local ud = Business.simulate(dear, 7200)
check(uc > ud, ("barato se vende más que caro (%d frente a %d)"):format(uc, ud))
check(cheap.Rep > dear.Rep, "barato sube la reputación; caro la baja")
local closed = Business.newRecord("L:c", "Local", "t", 1, "Ana", 1, 0)
closed.Type, closed.Open = "Fruteria", false
closed.Stock = { Agro_Manzana = 50 }
check(Business.simulate(closed, 7200) == 0 and closed.Stock.Agro_Manzana == 50, "cerrado no vende")
local long = Business.newRecord("L:l", "Local", "t", 1, "Ana", 1, 0)
long.Type, long.Open = "Fruteria", true
long.Stock = { Agro_Manzana = 500, Agro_Tomate = 500, Agro_Lechuga = 500 }
local u8 = Business.simulate(long, Business.MaxOfflineHours * 3600)
local long2 = Business.newRecord("L:l2", "Local", "t", 1, "Ana", 1, 0)
long2.Type, long2.Open = "Fruteria", true
long2.Stock = { Agro_Manzana = 500, Agro_Tomate = 500, Agro_Lechuga = 500 }
local u100 = Business.simulate(long2, 100 * 3600)
check(u100 == u8, "sin nadie mirando, como mucho se cuentan 8 horas")
local empty = Business.newRecord("L:e", "Local", "t", 1, "Ana", 1, 0)
empty.Type, empty.Open, empty.Till = "Fruteria", true, 5
Business.simulate(empty, 3600)
check(empty.Till == 0, "los gastos salen de la caja (sin bajar de 0)")
local g = Business.newRecord("G:1", "Gas", "t", 1, "Ana", 1, 0)
g.Type, g.Open = "Gasolinera", true
g.Stock = { W_Gasolina = 4000 }
local gu = Business.simulate(g, 3600)
check(gu > 50, ("una gasolinera vende litros a los vecinos (%d L/h)"):format(gu))
local ok, total = Business.sell(g, "W_Gasolina", 10)
check(ok and math.abs(total - 15) < 0.01, "repostar 10 L a 1,50 son 15 €")
check(not Business.sell(g, "W_Gasolina", 99999), "no se vende más de lo que hay")
check(Business.stars(3) == "★★★☆☆", "la reputación se ve en estrellas")

print("▶ Nombres de negocios (filtro de palabrotas)")
local NameFilter = load("src/shared/NameFilter")
local goodNames = { "Panadería La Espiga", "Computadoras Pepe", "Droguería Vergara", "Maricarmen Frutas", "Bar La Pola", "Café & Té", "Disputa de Sabores", "Hotel Mongolia", "Frutas Ñam", "Casa Lola 24" }
local okAll = true
for _, n in goodNames do
	local ok, why = NameFilter.check(n)
	if not ok then
		okAll = false
		print("    rechazado sin motivo: " .. n .. " (" .. tostring(why) .. ")")
	end
end
check(okAll, "los nombres normales se aceptan (también «Computadoras», «Vergara», «Maricarmen», «Pola»…)")
local badNames = { "Puta Tienda", "P.U.T.A", "put4 madre", "m i e r d a", "Mierrrrda", "Cabrones SL", "Hijo de puta", "Coño Bar", "FUCK shop", "Fuuuuck", "sh1t", "Gilipollas", "Nazi Store", "tiendaputamadre", "HIJ0PUT4" }
local blockedAll = true
for _, n in badNames do
	if NameFilter.check(n) then
		blockedAll = false
		print("    se ha colado: " .. n)
	end
end
check(blockedAll, "las palabrotas se bloquean aunque se escriban con trucos (P.U.T.A, put4, m i e r d a, puuuta…)")
check(not NameFilter.check("www.mitienda.com") and not NameFilter.check("Llama 612345678") and not NameFilter.check("<b>Hola</b>"), "nada de enlaces, teléfonos ni símbolos raros")
check(not NameFilter.check("ab") and not NameFilter.check(string.rep("a", 29)), "entre 3 y 28 letras")
local _, _, cleaned = NameFilter.check("   Horno   Ana  ")
check(cleaned == "Horno Ana", "se quitan los espacios de más")

print("▶ Personal y cadenas")
local base = Business.newRecord("L:p", "Local", "t", 1, "Ana", 1, 0)
base.Type, base.Open = "Fruteria", true
base.Stock = { Agro_Manzana = 500, Agro_Tomate = 500 }
local staffed = Business.newRecord("L:q", "Local", "t", 1, "Ana", 1, 0)
staffed.Type, staffed.Open, staffed.Npc = "Fruteria", true, 2
staffed.Stock = { Agro_Manzana = 500, Agro_Tomate = 500 }
local ub = Business.simulate(base, 3600)
local us = Business.simulate(staffed, 3600, { Shift = 1, Chain = 3 })
check(us > ub, ("con dependientes, un jugador de turno y cadena se vende más (%d frente a %d)"):format(us, ub))
check(Business.upkeep(staffed) == Business.Types.Fruteria.Upkeep + 2 * Business.NpcWage, "los dependientes cobran de los gastos")
check(math.abs(Business.boost(base, { Chain = 10 }) - (1 + Business.ChainMax)) < 0.001, "la cadena da como mucho un 30 % más")
check(Business.workerCount({ Workers = { ["1"] = { Name = "A", Wage = 6 }, ["2"] = { Name = "B", Wage = 9 } } } :: any) == 2, "se cuentan los empleados")

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
