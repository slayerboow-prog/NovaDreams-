-- cinemateca-revisiones: lee (SOLO LEE, con GetAsync) las revisiones de la Cinemateca que han guardado los
-- testers desde el juego (✅/❌, etiquetas, nota, plano, dispositivo). No escribe nada.
-- Están en su propio DataStore, «CinematecaRevisiones_v1» (server/Services/CinematecaService): «indice»
-- con las claves de cada día y, en cada una, la lista de revisiones cortas.
--
-- Uso: bash scripts/cloud-test.sh -v cinemateca-revisiones

local Cloud = Cloud :: any

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local store = DataStoreService:GetDataStore("CinematecaRevisiones_v1")
local okIndex, index = pcall(function()
	return store:GetAsync("indice")
end)
Cloud.check("Leer el índice de días", okIndex, if okIndex then ("%d claves"):format(if type(index) == "table" then #index else 0) else tostring(index))

local total, bad, good = 0, 0, 0
local byScene: { [string]: { ok: number, mal: number, notas: { string } } } = {}
for _, key in (if okIndex and type(index) == "table" then index else {}) do
	if Cloud.quedan() < 20 then
		Cloud.aviso("Tiempo", false, "se corta antes de leerlo todo")
		break
	end
	local ok, list = pcall(function()
		return store:GetAsync(key)
	end)
	if not ok then
		Cloud.aviso("Leer " .. key, false, tostring(list))
		continue
	end
	for _, r in (if type(list) == "table" then list else {}) do
		total += 1
		local scene = tostring(r.k)
		local entry = byScene[scene] or { ok = 0, mal = 0, notas = {} }
		byScene[scene] = entry
		if r.ok == 1 then
			good += 1
			entry.ok += 1
		else
			bad += 1
			entry.mal += 1
		end
		local bits = {}
		if type(r.g) == "table" and #r.g > 0 then
			table.insert(bits, "[" .. table.concat(r.g, ", ") .. "]")
		end
		if type(r.n) == "string" then
			table.insert(bits, r.n)
		end
		if r.s then
			table.insert(bits, ("plano %s/%s"):format(tostring(r.s), tostring(r.ss)))
		end
		if r.d then
			table.insert(bits, tostring(r.d))
		end
		if #bits > 0 then
			table.insert(entry.notas, table.concat(bits, " · "))
		end
		-- (cada revisión entera, para leerla con -v)
		print("[CINEMATECA] " .. key .. " " .. HttpService:JSONEncode(r))
	end
end
Cloud.info("revisiones", ("%d (✅ %d · ❌ %d)"):format(total, good, bad))
local names = {}
for scene in byScene do
	table.insert(names, scene)
end
table.sort(names, function(a, b)
	return byScene[a].mal > byScene[b].mal or (byScene[a].mal == byScene[b].mal and a < b)
end)
for _, scene in names do
	local e = byScene[scene]
	Cloud.check(("%s  ✅%d ❌%d"):format(scene, e.ok, e.mal), true, Cloud.lista(e.notas, 6))
end
return Cloud.resultado()
