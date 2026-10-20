-- TefraCraft: lo que se FABRICA en la Forja de Bastión (docs/planetas/diseno-mundos.md §2.2, versión
-- pequeña para Tefra; docs/planetas/tefra-misiones.md). Cuentas puras: las usan Services/TefraService
-- (la Forja: «Fabricar», con las recetas en una conversación de opciones) y las pruebas.
--
-- Materiales de Tefra (objetos de la mochila, shared/Items): obsidiana ígnea (oficios de la lava y
-- refinando en la Forja la obsidiana que minas a pie, la de la bodega de la nave), azufre negro (el
-- desactivador), cuarzo malva (el fundidor) y liquen térmico (el invernadero de setas de los Pozos).
-- Niveles (§2.2): 2 Común · 3 Refinado. Las recetas de nivel 3 hay que conseguirlas (misiones).

local TefraCraft = {}

export type Recipe = {
	Id: string, -- lo que sale (objeto de shared/Items)
	Name: string,
	Level: number,
	Makes: number,
	Needs: { [string]: number },
	Money: number, -- lo que cobra la Forja por el trabajo (€)
	Recipe: string?, -- objeto de receta que hace falta tener (y no se gasta)
	Desc: string,
}

TefraCraft.Recipes = {
	{
		Id = "GelTermico", Name = "Gel térmico (×2)", Level = 2, Makes = 2, Money = 5,
		Needs = { LiquenTermico = 1, AzufreNegro = 1 },
		Desc = "Úsalo en la mochila: baja el calor de golpe y un minuto casi no sube.",
	},
	{
		Id = "TrajeRefrigerado2", Name = "Traje refrigerado (nivel 2)", Level = 2, Makes = 1, Money = 60,
		Needs = { AzufreNegro = 2, CuarzoMalva = 2 },
		Desc = "Llevándolo en la mochila, el calor sube un 40 % menos.",
	},
	{
		Id = "TrajeRefrigerado3", Name = "Traje refrigerado (nivel 3)", Level = 3, Makes = 1, Money = 120, Recipe = "RecetaTraje3",
		Needs = { ObsidianaIgnea = 3, CuarzoMalva = 2, GelTermico = 1 },
		Desc = "El de los soldados de la Muralla: el calor sube un 60 % menos.",
	},
} :: { Recipe }

TefraCraft.ById = {}
for _, r in TefraCraft.Recipes do
	TefraCraft.ById[r.Id] = r
end

-- Refinar: la obsidiana de la bodega de la nave (data.Space.Ore.Obsidiana, la que se mina a pie en
-- Tefra) pasa a la mochila como obsidiana ígnea, de una en una, por RefineCost € cada una
TefraCraft.RefineOre = "Obsidiana"
TefraCraft.RefineItem = "ObsidianaIgnea"
TefraCraft.RefineCost = 3

-- ¿Se puede fabricar? items = { [id] = n }, money = dinero. Devuelve ok y lo que falta (texto)
function TefraCraft.check(id: string, items: { [string]: any }, money: number): (boolean, string?)
	local r = TefraCraft.ById[id]
	if not r then
		return false, "Esa receta no existe"
	end
	if r.Recipe and (tonumber(items[r.Recipe]) or 0) <= 0 then
		return false, "Te falta la receta"
	end
	local missing = {}
	local ids = {}
	for item in r.Needs do
		table.insert(ids, item)
	end
	table.sort(ids)
	for _, item in ids do
		local need = r.Needs[item]
		local have = tonumber(items[item]) or 0
		if have < need then
			table.insert(missing, ("%d %s"):format(need - have, item))
		end
	end
	if #missing > 0 then
		return false, "Te falta: " .. table.concat(missing, ", ")
	end
	if money < r.Money then
		return false, ("Te faltan %d €"):format(r.Money - money)
	end
	return true, nil
end

-- Lo que se gasta y lo que se gana (sin tocar nada: lo aplica quien llama)
function TefraCraft.plan(id: string): ({ [string]: number }, { [string]: number }, number)
	local r = TefraCraft.ById[id]
	if not r then
		return {}, {}, 0
	end
	return table.clone(r.Needs), { [r.Id] = r.Makes }, r.Money
end

return TefraCraft
