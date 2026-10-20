-- BuildingKeyMigration: arregla las partidas guardadas cuando una versión del mapa quita o mueve
-- edificios (la revisión del mapa, docs/mapa/revision/revision-mapa.md).
--
-- Las partidas guardan los edificios por su clave (InteriorService: "<Tipo>_<X>_<Z>"):
--   * data.Properties  viviendas compradas, alquiladas o la inicial ({ Key, Floor, Letter, Contract… })
--   * data.Housing.Home  la vivienda a la que te lleva «Ir a casa»
--   * data.Position  dónde estabas al salir (si era donde había un edificio quitado)
-- y BusinessService guarda los negocios por la clave del local ("L:<clave>", "H:x_z" de los hoteles).
-- Migrations/BuildingKeyMap (GENERADO por scripts/map/key-map.py) dice qué claves ya no existen y
-- sus sustitutos (mismo tipo, mismo distrito si se puede, el más cercano primero).
--
-- Funciones puras (sin servicios: las prueba scripts/test-buildingkeys.luau):
--   plan(data)                    qué entradas hay que mudar y a qué candidatos (nil = nada que hacer)
--   apply(data, plan, results)    aplica lo que el servidor consiguió (mudanza o devolución) y apunta
--                                 data.Housing.KeyMigration = Version: la segunda vez no hace nada
--                                 (va en Housing, que pasa a la vida nueva con las viviendas)
-- El servidor (HousingService.migrateKeys) prueba los candidatos en orden con el registro de dueños
-- (PropertyService.relocate: la misma planta y letra si vale y está libre; si no, la primera libre).

local Map = require(script.Parent.BuildingKeyMap)

local BuildingKeyMigration = {}

BuildingKeyMigration.Version = Map.Version
BuildingKeyMigration.Map = Map
BuildingKeyMigration.PositionMargin = 6 -- studs alrededor de un edificio quitado

export type Result = { Key: string, Floor: number, Letter: string?, Title: string?, Id: string?, Kind: string? } | { Refund: true }
export type Plan = {
	Entries: { { Index: number, Entry: { [string]: any }, Candidates: { string } } },
	Position: boolean,
}

-- Los sustitutos de una clave quitada (nil si la clave sigue existiendo)
function BuildingKeyMigration.candidates(key: any): { string }?
	return if type(key) == "string" then Map.Buildings[key] else nil
end

function BuildingKeyMigration.premiseCandidates(key: any): { string }?
	return if type(key) == "string" then Map.Premises[key] else nil
end

-- ¿Está (x, z) donde había un edificio quitado?
function BuildingKeyMigration.inRemoved(x: number, z: number): boolean
	local m = BuildingKeyMigration.PositionMargin
	for _, b in Map.Removed do
		if math.abs(x - b.X) <= b.W / 2 + m and math.abs(z - b.Z) <= b.D / 2 + m then
			return true
		end
	end
	return false
end

-- Qué hay que hacer con esta partida (nil = nada)
function BuildingKeyMigration.plan(data: any): Plan?
	if type(data) ~= "table" or (type(data.Housing) == "table" and data.Housing.KeyMigration == Map.Version) then
		return nil
	end
	local plan: Plan = { Entries = {}, Position = false }
	for i, entry in (if type(data.Properties) == "table" then data.Properties else {}) do
		local list = type(entry) == "table" and BuildingKeyMigration.candidates(entry.Key)
		if list then
			table.insert(plan.Entries, { Index = i, Entry = entry, Candidates = list })
		end
	end
	local p = data.Position
	if type(p) == "table" and type(p.X) == "number" and type(p.Z) == "number" and BuildingKeyMigration.inRemoved(p.X, p.Z) then
		plan.Position = true
	end
	return plan
end

local function sameUnit(a: any, key: string, floor: any, letter: any): boolean
	return type(a) == "table" and a.Key == key and a.Floor == floor and (a.Letter or "A") == (letter or "A")
end

-- Aplica el plan. results[i] (uno por plan.Entries[i]): la vivienda nueva o { Refund = true }.
-- Devuelve el resumen (Moved, Refunded = dinero devuelto, Lost = viviendas sin sustituto, Lines = textos
-- para el aviso).
function BuildingKeyMigration.apply(data: any, plan: Plan?, results: { Result }): { [string]: any }
	local summary = { Moved = 0, Refunded = 0, Lost = 0, DebtCleared = 0, Lines = {} }
	if type(data) ~= "table" then
		return summary
	end
	if type(data.Housing) ~= "table" then
		data.Housing = {}
	end
	if not plan then
		data.Housing.KeyMigration = Map.Version
		return summary
	end
	local housing = data.Housing
	local drop = {}
	for i, item in plan.Entries do
		local entry = item.Entry
		local result = results[i]
		local oldKey, oldFloor, oldLetter, oldTitle = entry.Key, entry.Floor, entry.Letter, entry.Title
		local wasHome = sameUnit(housing.Home, oldKey, oldFloor, oldLetter)
		if type(result) == "table" and type((result :: any).Key) == "string" then
			local r = result :: any
			entry.Key, entry.Floor, entry.Letter = r.Key, r.Floor, r.Letter or "A"
			if r.Title then
				entry.Title = r.Title
			end
			if r.Id then
				entry.Id = r.Id
			end
			if r.Kind then
				entry.Kind = r.Kind
			end
			entry.MovedFrom = oldKey
			if wasHome then
				housing.Home = { Key = entry.Key, Floor = entry.Floor, Letter = entry.Letter }
			end
			summary.Moved += 1
			table.insert(summary.Lines, ("%s → %s"):format(tostring(oldTitle or oldKey), tostring(r.Title or r.Key)))
		else
			-- Sin sitio en ningún sustituto: fuera de la lista y se devuelve lo pagado (compra), se
			-- perdona la deuda (alquiler) o se busca otra vivienda inicial
			table.insert(drop, item.Index)
			summary.Lost += 1
			if entry.Contract == "Compra" then
				local price = math.max(0, math.floor(tonumber(entry.Price) or 0))
				data.Money = math.max(0, math.floor(tonumber(data.Money) or 0)) + price
				summary.Refunded += price
			elseif entry.Contract == "Alquiler" then
				summary.DebtCleared += math.max(0, tonumber(entry.Debt) or 0)
			elseif entry.Contract == "Inicial" then
				housing.Assigned = nil -- (le llega otra vivienda inicial: HousingService.maybeAssignStarter)
			end
			table.insert(summary.Lines, tostring(entry.Title or oldKey))
			if wasHome then
				housing.Home = nil
			end
		end
	end
	table.sort(drop, function(a, b)
		return a > b
	end)
	for _, index in drop do
		table.remove(data.Properties, index)
	end
	-- «Ir a casa» a una vivienda que ya no está: a la primera que quede
	if type(housing.Home) == "table" and BuildingKeyMigration.candidates(housing.Home.Key) then
		housing.Home = nil
	end
	if housing.Home == nil and type(data.Properties) == "table" and data.Properties[1] then
		local first = data.Properties[1]
		housing.Home = { Key = first.Key, Floor = first.Floor, Letter = first.Letter or "A" }
	end
	-- Donde había un edificio quitado: se aparece en la entrada (o en la cama)
	if plan.Position then
		data.Position = nil
	end
	housing.KeyMigration = Map.Version
	return summary
end

-- El aviso para el jugador (nil si no hay nada que contar)
function BuildingKeyMigration.notice(summary: { [string]: any }): string?
	if summary.Moved == 0 and summary.Lost == 0 then
		return nil
	end
	local parts = {}
	if summary.Moved > 0 then
		table.insert(parts, ("tu vivienda se ha mudado a un edificio parecido de la zona (%s)"):format(table.concat(summary.Lines, "; ", 1, math.min(summary.Moved, 3))))
	end
	if summary.Refunded > 0 then
		table.insert(parts, ("te devolvemos %d € de una vivienda que ya no está"):format(summary.Refunded))
	elseif summary.Lost > 0 then
		table.insert(parts, "una vivienda que ya no está sale de tu lista" .. (if summary.DebtCleared > 0 then " y se perdona su deuda" else ""))
	end
	return "🏙️ Valmar se ha reordenado: " .. table.concat(parts, "; ") .. "."
end

return BuildingKeyMigration
