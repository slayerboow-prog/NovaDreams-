-- Prueba del cargador compartido de assets (World/AssetLoader.download) FUERA de Roblox, con Lune y
-- dobles de AssetService / InsertService.
--
-- Uso (desde la carpeta roblox/):  lune run scripts/test-assetloader.luau
--
-- Comprueba que (docs/diagnostico-v89.md §1b):
--   * primero prueba LoadAssetAsync y, si falla, InsertService:LoadAsset
--   * si fallan los dos, reintenta 3 veces esperando 2, 4 y 8 s, también con «not authorized»
--   * nunca hay más de MaxConcurrent (4–6) descargas a la vez, y todas acaban
--   * si no carga nunca, devuelve nil sin error
--   * todos los módulos de assets usan este cargador y siguen borrando los scripts antes de usar nada

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local task = require("@lune/task")

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local warnings: { string } = {}
local env = setmetatable({
	script = { Parent = {} },
	task = task,
	warn = function(msg)
		table.insert(warnings, tostring(msg))
	end,
	print = function() end,
	typeof = function(x)
		return if type(x) == "table" and rawget(x, "__asset") then "Instance" else type(x)
	end,
}, { __index = getfenv(1) })
local AssetLoader = luau.load(fs.readFile("src/server/World/AssetLoader.luau"), { debugName = "AssetLoader", environment = env })()

local function asset(id: number): any
	return { __asset = true, Id = id }
end
local NOT_AUTH = "User is not authorized to access Asset."

---------------------------------------------------------------------
print("Orden de los métodos y reintentos")
---------------------------------------------------------------------
check(#AssetLoader.Backoff == 3 and AssetLoader.Backoff[1] == 2 and AssetLoader.Backoff[2] == 4 and AssetLoader.Backoff[3] == 8, "3 reintentos con espera de 2, 4 y 8 s")
check(AssetLoader.MaxConcurrent >= 4 and AssetLoader.MaxConcurrent <= 6, ("como mucho %d descargas a la vez"):format(AssetLoader.MaxConcurrent))

do
	local calls = {}
	local d = AssetLoader.newDownloader({
		LoadAsync = function(id)
			table.insert(calls, "async")
			return asset(id)
		end,
		Insert = function(id)
			table.insert(calls, "insert")
			return asset(id)
		end,
		Wait = function() end,
		Warn = function() end,
	})
	local got = d.download(11)
	check(got and got.Id == 11 and #calls == 1 and calls[1] == "async", "primero LoadAssetAsync (si carga, no hace falta InsertService)")
end

do
	local calls = {}
	local d = AssetLoader.newDownloader({
		LoadAsync = function()
			table.insert(calls, "async")
			error(NOT_AUTH)
		end,
		Insert = function(id)
			table.insert(calls, "insert")
			return asset(id)
		end,
		Wait = function() end,
		Warn = function() end,
	})
	local got = d.download(12)
	check(got and got.Id == 12 and calls[1] == "async" and calls[2] == "insert" and d.Stats.Retries == 0, "si LoadAssetAsync falla, InsertService:LoadAsset")
end

do
	-- «not authorized» con los dos las dos primeras veces (como cuando todo pide a la vez); a la tercera, sí
	local tries, waits = 0, {}
	local d = AssetLoader.newDownloader({
		LoadAsync = function(id)
			tries += 1
			if tries < 3 then
				error(NOT_AUTH)
			end
			return asset(id)
		end,
		Insert = function()
			error(NOT_AUTH)
		end,
		Wait = function(s)
			table.insert(waits, s)
		end,
		Warn = function() end,
	})
	local got = d.download(96924659951632)
	check(got ~= nil and tries == 3 and #waits == 2 and waits[1] == 2 and waits[2] == 4, ("«not authorized» también se reintenta: carga al tercer intento (esperas %s)"):format(table.concat(waits, ", ")))
end

do
	local waits, attempts = {}, 0
	local said = {}
	local d = AssetLoader.newDownloader({
		LoadAsync = function()
			attempts += 1
			error(NOT_AUTH)
		end,
		Insert = function()
			error(NOT_AUTH)
		end,
		Wait = function(s)
			table.insert(waits, s)
		end,
		Warn = function(msg)
			table.insert(said, msg)
		end,
	})
	local ok, got = pcall(d.download, 101748452)
	check(ok and got == nil, "si no carga nunca: nil, sin error")
	check(attempts == 4 and #waits == 3 and waits[1] == 2 and waits[2] == 4 and waits[3] == 8 and d.Stats.Failed == 1, ("4 intentos en total, con esperas de %s s"):format(table.concat(waits, ", ")))
	check(#said == 1 and string.find(said[1], "101748452", 1, true) and string.find(said[1], "not authorized", 1, true), "un solo aviso al final, con el id y el error")
end

do
	-- Un doble que devuelve basura (no es una instancia) cuenta como fallo
	local d = AssetLoader.newDownloader({
		LoadAsync = function()
			return "nada"
		end,
		Wait = function() end,
		Warn = function() end,
	})
	check(d.download(5) == nil, "lo que no es una instancia no vale")
end

---------------------------------------------------------------------
print("Cola global")
---------------------------------------------------------------------
do
	local active, peak, done = 0, 0, 0
	local d = AssetLoader.newDownloader({
		MaxConcurrent = 5,
		LoadAsync = function(id)
			active += 1
			peak = math.max(peak, active)
			task.wait(0.02)
			active -= 1
			if id % 7 == 0 and not (id > 1000) then
				error(NOT_AUTH) -- (los múltiplos de 7 no cargan nunca: se reintentan y acaban en nil)
			end
			return asset(id)
		end,
		Insert = function()
			error(NOT_AUTH)
		end,
		Wait = function(s)
			task.wait(s / 200) -- (2, 4 y 8 s, pero rápido)
		end,
		Warn = function() end,
	})
	local results = {}
	local total = 30
	for i = 1, total do
		task.spawn(function()
			local id = if i % 7 == 0 then i else i + 2000
			results[i] = d.download(id)
			done += 1
		end)
	end
	local t0 = os.clock()
	while done < total and os.clock() - t0 < 10 do
		task.wait(0.01)
	end
	local all = true
	for i = 1, total do
		if i % 7 ~= 0 and not results[i] then
			all = false
		end
	end
	check(done == total, ("todas las descargas acaban (%d de %d)"):format(done, total))
	check(peak <= 5 and d.Stats.Peak <= 5 and peak >= 4, ("nunca más de 5 a la vez (máximo visto: %d)"):format(peak))
	check(all and d.Stats.Queued > 0, ("las que esperaban su turno también cargan (%d esperaron en la cola)"):format(d.Stats.Queued))
	check(d.Stats.Active == 0, "al acabar no queda ningún sitio ocupado")
end

---------------------------------------------------------------------
print("Todos los módulos usan el cargador compartido")
---------------------------------------------------------------------
local users = {
	"src/server/World/NatureAssets.luau",
	"src/server/World/UserMaterials.luau",
	"src/server/World/SkyAssets.luau",
	"src/server/World/SkyLoader.luau",
	"src/server/World/Kit/CarBodies.luau",
	"src/server/World/Buildings3D.luau",
	"src/server/World/WorkshopProps.luau",
	"src/server/World/InteriorProps.luau",
	"src/server/World/UserArsenal.luau",
}
local own = {}
for _, path in users do
	local src = fs.readFile(path)
	local code = src:gsub("%-%-[^\n]*", "") -- (sin comentarios)
	if not code:find("AssetLoader", 1, true) or code:find(":LoadAssetAsync(", 1, true) or code:find(":LoadAsset(", 1, true) then
		table.insert(own, path)
	end
end
check(#own == 0, "NatureAssets, UserMaterials, SkyAssets, SkyLoader, CarBodies, Buildings3D, WorkshopProps, InteriorProps y UserArsenal: sin cargador propio " .. table.concat(own, ", "))
local cityAssets = fs.readFile("src/server/World/CityAssets.luau")
local userMaterials = fs.readFile("src/server/World/UserMaterials.luau")
check(cityAssets:find("Buildings3D).loadAsset", 1, true) and userMaterials:find("load or download", 1, true), "CityAssets (por Buildings3D) y MaterialExtras, StreetDress, HouseDress e InteriorDress (por UserMaterials) también")
-- Lo cargado llega sin padre y cada módulo borra los scripts antes de usarlo (como antes)
local loaderSrc = fs.readFile("src/server/World/AssetLoader.luau")
local downloadBody = loaderSrc:match("function AssetLoader.newDownloader(.-)\nend\n") or ""
check(not downloadBody:find(".Parent =", 1, true), "el cargador nunca le pone padre a lo que carga")
local nature = fs.readFile("src/server/World/NatureAssets.luau")
local arsenal = fs.readFile("src/server/World/UserArsenal.luau")
check(nature:find("LO PRIMERO: fuera todos los scripts", 1, true) and arsenal:find("MeshLibrary.stripScripts(asset)", 1, true), "y los módulos siguen borrando los scripts nada más llegar")

print()
if failures > 0 then
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
print("✅ Cargador de assets: todo bien")
