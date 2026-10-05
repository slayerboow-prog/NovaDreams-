-- AssetLoader: el ÚNICO cargador de assets de la Tienda del servidor (AssetLoader.download), y la carga
-- de los packs gratuitos y oficiales de Synty que se guardan en ServerStorage.AssetLibrary.
--
-- download(id) (lo usan World/NatureAssets, UserMaterials (y StreetDress, HouseDress, InteriorDress,
-- MaterialExtras), SkyAssets, SkyLoader, Kit/CarBodies, Buildings3D (y CityAssets), WorkshopProps,
-- InteriorProps y UserArsenal):
--   * Primero AssetService:LoadAssetAsync (con AssetService.AllowInsertFreeAssets = true en
--     default.project.json carga también los de la comunidad); si falla, InsertService:LoadAsset (solo
--     los oficiales y los del dueño).
--   * Reintentos: si fallan los dos, se espera 2, 4 y 8 s y se vuelve a probar (3 reintentos), TAMBIÉN con
--     «User is not authorized to access Asset.»: en un servidor de verdad, cuando todo pide a la vez,
--     Roblox contesta con ese error a ids que sí cargan solos (docs/diagnostico-v89.md §1b).
--   * Cola: como mucho MaxConcurrent descargas a la vez en todo el servidor (los demás esperan su
--     turno, por orden de llegada); la espera entre reintentos no ocupa sitio en la cola.
--   * Devuelve lo cargado SIN PADRE (nunca lo mete en ningún sitio): cada módulo borra los scripts antes
--     de usarlo (MeshLibrary.stripScripts, CityAssetsKit.sanitize…), igual que antes.
--   * nil si no hay manera (nunca lanza error). Si tampoco funciona, el juego sigue con lo hecho por código.
--
-- AssetLoader.newDownloader(opts) hace otro cargador con dobles (las pruebas: scripts/test-assetloader).

local AssetLoader = {}

AssetLoader.Packs = {
	{ Name = "SyntyCity", Id = 6933556508 }, -- Synty City Pack
	{ Name = "SyntyNature", Id = 6933438443 }, -- Synty Nature Pack
}

AssetLoader.Backoff = { 2, 4, 8 } -- segundos de espera antes de cada reintento
AssetLoader.MaxConcurrent = 5 -- descargas a la vez en todo el servidor (4–6)

export type Options = {
	LoadAsync: ((number) -> any)?, -- AssetService:LoadAssetAsync
	Insert: ((number) -> any)?, -- InsertService:LoadAsset
	Wait: ((number) -> ())?, -- task.wait
	Backoff: { number }?,
	MaxConcurrent: number?,
	Warn: ((string) -> ())?,
	Tag: string?, -- prefijo de los avisos
}

export type Downloader = {
	download: (number) -> Instance?,
	Stats: { Active: number, Peak: number, Queued: number, Attempts: number, Retries: number, Failed: number },
}

-- Un cargador con su propia cola (el de verdad, abajo, usa los servicios de Roblox)
function AssetLoader.newDownloader(opts: Options?): Downloader
	local o = opts or {}
	local backoff = o.Backoff or AssetLoader.Backoff
	local max = math.max(1, o.MaxConcurrent or AssetLoader.MaxConcurrent)
	local wait = o.Wait or function(s: number)
		task.wait(s)
	end
	local say = o.Warn or warn
	local tag = o.Tag or "[Assets]"
	local stats = { Active = 0, Peak = 0, Queued = 0, Attempts = 0, Retries = 0, Failed = 0 }
	local waiting: { thread } = {}

	-- Semáforo: un sitio en la cola (si no hay, el hilo espera dormido hasta que se lo pasen)
	local function acquire()
		if stats.Active < max then
			stats.Active += 1
		else
			stats.Queued += 1
			table.insert(waiting, coroutine.running())
			coroutine.yield()
			-- (quien sale nos pasa su sitio: Active no cambia)
		end
		stats.Peak = math.max(stats.Peak, stats.Active)
	end
	local function release()
		local nextThread = table.remove(waiting, 1)
		if nextThread then
			task.spawn(nextThread)
		else
			stats.Active -= 1
		end
	end

	local function isInstance(x: any): boolean
		return typeof(x) == "Instance" or (type(x) == "table" and x ~= nil)
	end

	-- Un intento: LoadAssetAsync y, si falla, InsertService
	local function attempt(id: number): (any, string?)
		stats.Attempts += 1
		local errA, errB = "sin LoadAssetAsync", "sin InsertService"
		if o.LoadAsync then
			local ok, result = pcall(o.LoadAsync, id)
			if ok and result and isInstance(result) then
				return result, nil
			end
			errA = tostring(result)
		end
		if o.Insert then
			local ok, result = pcall(o.Insert, id)
			if ok and result and isInstance(result) then
				return result, nil
			end
			errB = tostring(result)
		end
		return nil, errA .. " / " .. errB
	end

	local function download(id: number): Instance?
		local lastErr: string? = nil
		for try = 0, #backoff do
			if try > 0 then
				stats.Retries += 1
				wait(backoff[try]) -- (fuera de la cola: no ocupa sitio mientras espera)
			end
			acquire()
			local okRun, asset, err = pcall(attempt, id)
			release()
			if okRun and asset then
				if try > 0 then
					say(("%s %d cargó al reintento %d"):format(tag, id, try))
				end
				return asset
			end
			lastErr = if okRun then err else tostring(asset)
		end
		stats.Failed += 1
		say(("%s no carga %d tras %d intentos: %s"):format(tag, id, #backoff + 1, tostring(lastErr)))
		return nil
	end

	return { download = download, Stats = stats }
end

-- El cargador del servidor (uno para todos los módulos: así la cola es global)
local shared: Downloader? = nil
local function real(): Downloader
	if not shared then
		local AssetService = game:GetService("AssetService")
		local InsertService = game:GetService("InsertService")
		shared = AssetLoader.newDownloader({
			LoadAsync = function(id: number)
				return (AssetService :: any):LoadAssetAsync(id)
			end,
			Insert = function(id: number)
				return InsertService:LoadAsset(id)
			end,
		})
	end
	return shared :: Downloader
end

function AssetLoader.download(id: number): Instance?
	return real().download(id)
end

-- (para /debug y las pruebas en un servidor: cuántas descargas, reintentos y fallos)
function AssetLoader.stats(): { [string]: number }
	return real().Stats
end

-- Devuelve cuántos packs hay disponibles (ya guardados en el archivo o descargados ahora)
function AssetLoader.load(): number
	local ServerStorage = game:GetService("ServerStorage")
	local AssetLibrary = require(script.Parent.Kit.AssetLibrary)
	local library = ServerStorage:FindFirstChild("AssetLibrary")
	if not library then
		library = Instance.new("Folder")
		library.Name = "AssetLibrary"
		library.Parent = ServerStorage
	end

	local available = 0
	for _, pack in AssetLoader.Packs do
		if library:FindFirstChild(pack.Name) then
			available += 1
		else
			local asset = AssetLoader.download(pack.Id)
			if asset then
				asset.Name = pack.Name
				asset.Parent = library
				available += 1
			end
		end
	end

	-- Resumen en la ventana Output para saber qué modelos se están usando
	local summary = {}
	for kind in AssetLibrary.Catalog do
		table.insert(summary, ("%s=%d"):format(kind, #AssetLibrary.variants(kind)))
	end
	table.sort(summary)
	print(("[Assets] Packs disponibles: %d/%d · %s"):format(available, #AssetLoader.Packs, table.concat(summary, " ")))
	return available
end

return AssetLoader
