-- Prueba de las claves de los edificios (lo que guardan las partidas) tras la revisión del mapa.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-buildingkeys.luau            (la migración de las partidas, con datos de mentira)
--   lune run scripts/test-buildingkeys.luau X.rbxl     (y además el mapa construido:
--       rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl)
--
-- Comprueba que:
--   * Migrations/BuildingKeyMigration muda las viviendas de los edificios quitados (con su contrato,
--     planta y letra nuevas, «Ir a casa» detrás), devuelve lo pagado si no hay sitio (compra), perdona
--     la deuda (alquiler) o deja buscar otra vivienda inicial, quita el sitio guardado donde había un
--     edificio quitado, avisa una vez y la segunda vez no hace nada
--   * con el mapa: TODA clave de edificio y de negocio del mapa de antes de la revisión
--     (scripts/map/data/claves-v1.json, igual que el publicado) sigue existiendo o está en
--     Migrations/BuildingKeyMap con algún sustituto que existe y es del mismo tipo; y ningún
--     sustituto del mapa apunta a una clave que no existe

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local L = require("./lib/ModuleLoader")
local check = L.check

local Migration = L.load("src/server/Migrations/BuildingKeyMigration")
local Map = Migration.Map

---------------------------------------------------------------------
print("\n▶ 1. La migración de las partidas (datos de mentira)")
---------------------------------------------------------------------
-- Unas claves quitadas de verdad (del mapa generado) de cada tipo
local removedCasa, removedPortal
for key in Map.Buildings do
	if not removedCasa and string.sub(key, 1, 5) == "Casa_" then
		removedCasa = key
	elseif not removedPortal and string.sub(key, 1, 7) == "Portal_" then
		removedPortal = key
	end
end
check(removedCasa ~= nil and removedPortal ~= nil, "el mapa de claves tiene casas y pisos quitados")
local where = Map.Removed[removedCasa]

local data = {
	Money = 100,
	Properties = {
		{ Key = removedCasa, Floor = 0, Letter = "A", Kind = "Casa", Title = "Casa vieja", Price = 3200, Contract = "Compra", Since = 10 },
		{ Key = "Casa_99999_99999", Floor = 0, Letter = "A", Kind = "Casa", Title = "Casa que sigue", Price = 3000, Contract = "Compra" },
		{ Key = removedPortal, Floor = 3, Letter = "A", Kind = "Piso", Title = "Piso alquilado", Price = 0, Contract = "Alquiler", Rent = 60, Debt = 120, Unpaid = 2 },
	},
	Housing = { Home = { Key = removedCasa, Floor = 0, Letter = "A" }, Assigned = true },
	Position = { X = where.X, Y = 3, Z = where.Z, Yaw = 0 },
}
local plan = Migration.plan(data)
check(plan ~= nil and #plan.Entries == 2, "el plan encuentra las 2 viviendas de edificios quitados (y no la que sigue)")
check(plan ~= nil and plan.Position, "el sitio guardado estaba donde había un edificio quitado")
check(plan ~= nil and #plan.Entries[1].Candidates > 0, "cada vivienda quitada tiene sustitutos")
-- La primera se muda; la segunda no tiene sitio
local summary = Migration.apply(data, plan, {
	{ Key = "Casa_1_2", Floor = 0, Letter = "A", Title = "Casa nueva", Id = "C-1", Kind = "Casa" },
	{ Refund = true },
})
local first = data.Properties[1]
check(first.Key == "Casa_1_2" and first.Contract == "Compra" and first.Price == 3200 and first.Since == 10 and first.MovedFrom == removedCasa, "la casa se muda con su contrato, su precio y su fecha")
check(data.Housing.Home and data.Housing.Home.Key == "Casa_1_2", "«Ir a casa» va a la casa nueva")
check(#data.Properties == 2 and data.Properties[2].Key == "Casa_99999_99999", "el alquiler sin sitio sale de la lista; la casa que sigue, igual")
check(data.Money == 100 and summary.DebtCleared == 120, "un alquiler sin sitio: no se devuelve nada y se perdona su deuda")
check(data.Position == nil, "el sitio guardado donde había un edificio quitado se borra (aparece en la entrada o en su cama)")
check(summary.Moved == 1 and summary.Lost == 1, "resumen: 1 mudada y 1 sin sitio")
local text = Migration.notice(summary)
check(type(text) == "string" and string.find(text, "Casa nueva", 1, true) ~= nil, "aviso para el jugador: " .. tostring(text))
check(Migration.plan(data) == nil, "la segunda vez no hay nada que hacer (idempotente)")
-- Compra sin sitio: se devuelve lo pagado; vivienda inicial sin sitio: le llegará otra
local data2 = {
	Money = 50,
	Properties = {
		{ Key = removedCasa, Floor = 0, Letter = "A", Kind = "Casa", Price = 3500, Contract = "Compra" },
		{ Key = removedPortal, Floor = 2, Letter = "A", Kind = "Piso", Price = 0, Contract = "Inicial" },
	},
	Housing = { Home = { Key = removedPortal, Floor = 2, Letter = "A" }, Assigned = true },
}
local plan2 = Migration.plan(data2)
local summary2 = Migration.apply(data2, plan2, { { Refund = true }, { Refund = true } })
check(data2.Money == 3550 and summary2.Refunded == 3500, "una compra sin sitio: se devuelve lo que costó")
check(#data2.Properties == 0 and data2.Housing.Assigned == nil and data2.Housing.Home == nil, "la vivienda inicial sin sitio: fuera, y se le buscará otra")
check(Migration.plan(data2) == nil, "y la segunda vez nada")
-- Partidas sin nada que mudar: se marca y ya
local data3 = { Money = 0, Properties = { { Key = "Casa_99999_99999", Floor = 0, Contract = "Compra", Price = 10 } }, Housing = {} }
local plan3 = Migration.plan(data3)
check(plan3 ~= nil and #plan3.Entries == 0, "sin viviendas quitadas, el plan está vacío")
Migration.apply(data3, plan3, {})
check(data3.Housing.KeyMigration == Migration.Version and Migration.plan(data3) == nil, "y queda marcada (Housing.KeyMigration, pasa a la vida nueva)")
check(Migration.plan({ Money = 0 }) ~= nil, "una partida vieja sin Housing también se mira")

---------------------------------------------------------------------
-- 2. Con el mapa construido: las claves de antes existen o están en el mapa
---------------------------------------------------------------------
local placePath = process.args[1]
if placePath then
	print("\n▶ 2. Las claves del mapa de antes en el mapa construido (" .. placePath .. ")")
	local run = (process :: any).exec or (process :: any).spawn
	local result = run("lune", { "run", "scripts/map/building-keys.luau", placePath, "/tmp/_claves_actuales.json" })
	check(result.ok, "se exportan las claves del mapa construido")
	local now = serde.decode("json", fs.readFile("/tmp/_claves_actuales.json"))
	local old = serde.decode("json", fs.readFile(("scripts/map/data/claves-v%d.json"):format(Map.Version)))
	local nowB, nowP = {}, {}
	for _, b in now.Buildings do
		nowB[b.Key] = b
	end
	for _, p in now.Premises do
		nowP[p.Key] = p
	end
	local kindOf = function(key: string): string
		return (string.match(key, "^(%a+)_") or "")
	end
	local COMPATIBLE = { Casa = { Casa = true, Villa = true }, Villa = { Villa = true, Casa = true }, Portal = { Portal = true, Local = true }, Local = { Local = true, Portal = true } }
	local missing, badTarget, kept, mapped = {}, {}, 0, 0
	for _, key in old.Buildings do
		if nowB[key] then
			kept += 1
		else
			local list = Map.Buildings[key]
			local okOne = false
			for _, cand in list or {} do
				local target = nowB[cand]
				local want = COMPATIBLE[kindOf(key)] or { [kindOf(key)] = true }
				if target and want[target.Kind] then
					okOne = true
				end
			end
			if okOne then
				mapped += 1
			else
				table.insert(missing, key)
			end
		end
	end
	for key, list in Map.Buildings do
		for _, cand in list do
			if not nowB[cand] then
				table.insert(badTarget, key .. " → " .. cand)
			end
		end
	end
	print(("     %d edificios de antes: %d siguen con la misma clave, %d se mudan (en el mapa)"):format(#old.Buildings, kept, mapped))
	check(#missing == 0, ("toda clave de edificio de antes sigue o está en el mapa con un sustituto que existe%s"):format(if #missing > 0 then " (" .. table.concat(missing, ", ", 1, math.min(#missing, 6)) .. ")" else ""))
	check(#badTarget == 0, ("ningún sustituto apunta a un edificio que no existe%s"):format(if #badTarget > 0 then " (" .. table.concat(badTarget, ", ", 1, math.min(#badTarget, 6)) .. ")" else ""))
	local pMissing, pKept, pMapped = {}, 0, 0
	for _, key in old.Premises do
		if nowP[key] then
			pKept += 1
		else
			local okOne = false
			for _, cand in Map.Premises[key] or {} do
				if nowP[cand] and string.sub(cand, 1, 2) == string.sub(key, 1, 2) then
					okOne = true
				end
			end
			if okOne then
				pMapped += 1
			else
				table.insert(pMissing, key)
			end
		end
	end
	print(("     %d negocios de antes: %d siguen, %d se mudan"):format(#old.Premises, pKept, pMapped))
	check(#pMissing == 0, ("toda clave de negocio de antes sigue o está en el mapa%s"):format(if #pMissing > 0 then " (" .. table.concat(pMissing, ", ", 1, math.min(#pMissing, 6)) .. ")" else ""))
	-- Las que siguen: ni una clave nueva para un edificio que ya estaba (la revisión solo quita)
	local fresh = 0
	local oldSet = {}
	for _, key in old.Buildings do
		oldSet[key] = true
	end
	for key in nowB do
		if not oldSet[key] then
			fresh += 1
		end
	end
	print(("     %d edificios con clave nueva (lugares emblemáticos que han girado o cambiado de manzana)"):format(fresh))
	check(kept >= #old.Buildings * 0.6, "la mayoría de los edificios conservan su clave")
end

L.finish("Claves de los edificios")
