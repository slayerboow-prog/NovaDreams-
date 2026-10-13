-- diag-partida: lee (SOLO LEE, con GetAsync) la partida guardada de unos jugadores y resume lo importante
--
-- Para saber si una partida se ha perdido o pisado: dinero, nivel, día, historia, inventario, bloqueo de
-- sesión y última vez conectado. No escribe nada en el DataStore.
-- Jugadores: el dueño del juego y los nombres de DIAG_NOMBRES (abajo).
--
-- Uso: bash scripts/cloud-test.sh -v diag-partida

local Cloud = Cloud :: any

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Config = require(Cloud.Shared.Config)

local DIAG_NOMBRES = { "Sibuastian" }

local ids = {}
if game.CreatorType == Enum.CreatorType.User and game.CreatorId ~= 0 then
	table.insert(ids, game.CreatorId)
end
for _, name in DIAG_NOMBRES do
	local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, name)
	if ok and type(id) == "number" and not table.find(ids, id) then
		table.insert(ids, id)
	end
end

local store = DataStoreService:GetDataStore(Config.DataStoreName)
local function count(t: any): number
	local n = 0
	if type(t) == "table" then
		for _ in t do
			n += 1
		end
	end
	return n
end
local function short(v: any): string
	if type(v) == "table" then
		local bits = {}
		for k, x in v do
			if type(x) ~= "table" then
				table.insert(bits, tostring(k) .. "=" .. tostring(x))
			else
				table.insert(bits, tostring(k) .. "={" .. count(x) .. "}")
			end
			if #bits >= 12 then
				break
			end
		end
		return "{" .. table.concat(bits, ",") .. "}"
	end
	return tostring(v)
end
for _, id in ids do
	local ok, data, info = pcall(function()
		return store:GetAsync("Player_" .. id)
	end)
	if not ok then
		Cloud.check("Partida de " .. id, false, "GetAsync: " .. tostring(data))
		continue
	end
	if type(data) ~= "table" then
		Cloud.check("Partida de " .. id, false, "no hay partida guardada")
		continue
	end
	local lock = data.SessionLock
	local story = data.Story or {}
	local parts = {
		("Money=%s"):format(tostring(data.Money)),
		("Life=%s"):format(short(data.Life)),
		("Hunger=%s Energy=%s"):format(tostring(data.Hunger), tostring(data.Energy)),
		("Story: chapters=%d active=%d completed=%d PrologueDone=%s"):format(count(story.Chapters), count(story.Active), count(story.Completed), tostring(story.PrologueDone)),
		("Progress=%s"):format(short(data.Progress)),
		("Calendar=%s"):format(short(data.Calendar)),
		("Stats=%s"):format(short(data.Stats)),
		("LastOnline=%s (hace %s s)"):format(tostring(data.LastOnline), tostring(type(data.LastOnline) == "number" and os.time() - data.LastOnline or "?")),
		("SessionLock=%s"):format(if type(lock) == "table" then ("JobId=%s hace %s s"):format(string.sub(tostring(lock.JobId), 1, 8), tostring(os.time() - (lock.Time or 0))) else "ninguno"),
		("Version=%s Updated=%s"):format(tostring(info and info.Version), tostring(info and info.UpdatedTime)),
	}
	local keys = {}
	for k, v in data do
		if type(v) ~= "table" then
			table.insert(keys, tostring(k) .. "=" .. string.sub(tostring(v), 1, 20))
		else
			table.insert(keys, tostring(k) .. "{" .. count(v) .. "}")
		end
	end
	table.sort(keys)
	table.insert(parts, "claves: " .. table.concat(keys, ", "))
	Cloud.check("Partida de " .. id, true, table.concat(parts, " | "))
	-- Versiones anteriores de la misma clave (solo lectura) para ver si antes tenía más dinero o nivel
	local okList, pages = pcall(function()
		return store:ListVersionsAsync("Player_" .. id, Enum.SortDirection.Descending, nil, nil, 8)
	end)
	if okList and pages then
		for _, v in pages:GetCurrentPage() do
			local okV, old = pcall(function()
				return store:GetVersionAsync("Player_" .. id, v.Version)
			end)
			if okV and type(old) == "table" then
				local prog = old.Progress or {}
				local cal = old.Calendar or {}
				Cloud.check(("Versión guardada de %d (%s)"):format(id, os.date("!%Y-%m-%d %H:%M", math.floor(v.CreatedTime / 1000))), true, ("%s: Money=%s Level=%s Day=%s PlaySeconds=%s"):format(
					string.sub(tostring(v.Version), -12),
					tostring(old.Money), tostring(prog.Level), tostring(cal.Day), tostring(old.Stats and old.Stats.PlaySeconds)))
				-- Lo que puede quitar dinero (modo pruebas, Hacienda, multas, alquiler, cambio de vida)
				local flags = type(old.Story) == "table" and old.Story.Flags or nil
				Cloud.check(("  ↳ dinero en %s"):format(string.sub(tostring(v.Version), -12)), true, ("Tester=%s | Tax=%s | Record=%d Jail=%s | Conduct=%s | Housing=%s | Life=%s | SinDinero=%s | MoneyEarned=%s TasksDone=%s | Items=%d Vehicles=%d"):format(
					short(old.Tester), short(old.Tax), count(old.Record), short(old.Jail), short(old.Conduct), short(old.Housing), short(old.Life),
					tostring(type(flags) == "table" and flags.SinDinero), tostring(old.Stats and old.Stats.MoneyEarned), tostring(old.Stats and old.Stats.TasksDone),
					count(old.Items), count(old.Vehicles)))
				local props = {}
				for _, e in (if type(old.Properties) == "table" then old.Properties else {}) do
					if type(e) == "table" then
						table.insert(props, ("%s %s Rent=%s Debt=%s Unpaid=%s"):format(tostring(e.Title or e.Id), tostring(e.Contract), tostring(e.Rent), tostring(e.Debt), tostring(e.Unpaid)))
					end
				end
				Cloud.check(("  ↳ viviendas en %s"):format(string.sub(tostring(v.Version), -12)), true, if #props > 0 then table.concat(props, " ; ") else "ninguna")
			end
		end
	else
		Cloud.aviso("Versiones de " .. id, false, "ListVersionsAsync: " .. tostring(pages))
	end
end
return Cloud.resultado()
