-- Prueba: el servidor SIEMPRE termina de arrancar y el reloj SIEMPRE corre (Lune).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-serverboot.luau        (~10 s)
--
-- Por qué existe (v107/v108, móvil): el dueño entraba y veía «Nv. 1 · 0 € · Lunes, 1 de enero · Día 1»,
-- el reloj parado en las 8:00, la barra rápida vacía y sin misiones: los valores por defecto del
-- cliente. Main.server.luau arrancaba los ~100 servicios seguidos con un pcall cada uno, pero un pcall no
-- protege de un servicio que se queda esperando, y los pasos del mundo de antes no tenían pcall: los de
-- detrás (reloj, nivel, mochila, historia) no arrancaban nunca. Comprueba:
--   1. Boot.step: un paso con error, uno que se queda esperando para siempre y uno lento no impiden los
--      siguientes; nunca se espera más del tiempo máximo; se apunta todo; ServerReady al final.
--   2. Main.server.luau de verdad, con un mundo y unos servicios de mentira donde el terreno falla, un
--      servicio da error, otro se queda colgado y WorldService no pone el reloj: se llaman TODOS los
--      servicios de la lista en orden, el reloj se pone en marcha igual y workspace.ServerReady = true.
--   3. WorldService de verdad: el reloj corre desde el primer momento (aunque falle lo demás de init) y
--      un ClockSpeed del cole a 0 no lo para.
--   4. Lo que espera el cliente: UI/LoadingGate (ServerReady, DataLoaded, StoryReady) y UI/ServerWait
--      (no se rinde mientras el servidor arranca; nil solo si ya listo no aparece).

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function signal()
	local handlers = {}
	return {
		Connect = function(_, fn)
			table.insert(handlers, fn)
			return { Disconnect = function() end }
		end,
		Fire = function(_, ...)
			for _, fn in table.clone(handlers) do
				fn(...)
			end
		end,
		Count = function()
			return #handlers
		end,
	}
end

local function attrs(name: string): any
	local self: any = { Name = name, __a = {}, __s = {}, __children = {} }
	function self:GetAttribute(k)
		return self.__a[k]
	end
	function self:SetAttribute(k, v)
		self.__a[k] = v
		if self.__s[k] then
			self.__s[k]:Fire()
		end
	end
	function self:GetAttributeChangedSignal(k)
		self.__s[k] = self.__s[k] or signal()
		return self.__s[k]
	end
	function self:FindFirstChild(n)
		return self.__children[n]
	end
	return self
end

local warnings: { string } = {}
local function fakeWarn(...)
	local parts = {}
	for _, v in { ... } do
		table.insert(parts, tostring(v))
	end
	table.insert(warnings, table.concat(parts, " "))
end
local function warned(fragment: string): boolean
	for _, w in warnings do
		if string.find(w, fragment, 1, true) then
			return true
		end
	end
	return false
end

local function loadModule(path: string, env: { [string]: any }): any
	return luau.load(fs.readFile(path), { debugName = path, environment = setmetatable(env, { __index = _G }) })()
end

---------------------------------------------------------------------
print("\n▶ 1. Boot.step: ningún paso deja sin arrancar a los siguientes")
---------------------------------------------------------------------
local ws1 = attrs("Workspace")
local Boot = loadModule("src/server/Boot.luau", { workspace = ws1, task = task, warn = fakeWarn })
Boot.StepTimeout = 0.3
do
	local ran = {}
	local t0 = os.clock()
	check(Boot.step("Bien", function()
		table.insert(ran, "Bien")
	end), "Un paso que va bien devuelve true")
	check(not Boot.step("Falla", function()
		error("se rompe")
	end), "Un paso con error devuelve false…")
	check(warned("Error iniciando Falla") and warned("se rompe"), "…y se avisa con el motivo")
	local t1 = os.clock()
	check(not Boot.step("Colgado", function()
		task.wait(1e6)
	end), "Un paso que se queda esperando para siempre devuelve false…")
	check(os.clock() - t1 < 1.5, ("…sin esperar más de su tiempo máximo (%.2f s)"):format(os.clock() - t1))
	check(warned("Colgado sigue sin terminar"), "…y se avisa")
	check(Boot.step("Lento pero a tiempo", function()
		task.wait(0.1)
		table.insert(ran, "Lento")
	end), "Un paso que espera un poco (menos que el máximo) termina bien")
	check(Boot.step("Después", function()
		table.insert(ran, "Después")
	end), "Los pasos de detrás siguen arrancando")
	check(#ran == 3 and ran[3] == "Después", "Se han hecho los pasos en orden (" .. table.concat(ran, ", ") .. ")")
	check(Boot.errors == 1 and Boot.timeouts == 1 and #Boot.results == 5, ("Se apunta cada paso (errores %d, sin terminar %d, pasos %d)"):format(Boot.errors, Boot.timeouts, #Boot.results))
	check(ws1:GetAttribute("ServerReady") == nil, "Hasta Boot.ready no se dice que el servidor está listo")
	Boot.ready()
	check(ws1:GetAttribute("ServerReady") == true and ws1:GetAttribute("ServerBootErrors") == 2, "Boot.ready: ServerReady = true y cuántos pasos fallaron")
	check(os.clock() - t0 < 3, "Todo en poco tiempo")
end

---------------------------------------------------------------------
print("\n▶ 2. Main.server.luau: con el mundo roto y servicios que fallan o se cuelgan, arranca todo")
---------------------------------------------------------------------
do
	local mainSrc = fs.readFile("src/server/Main.server.luau")
	local orderBlock = string.match(mainSrc, "local order = {(.-)\n}")
	local order = {}
	for name in string.gmatch(orderBlock or "", '\n%s*"([%w_]+)"') do
		table.insert(order, name)
	end
	check(#order >= 90, ("Main tiene la lista de servicios (%d)"):format(#order))
	local missing = {}
	for _, name in order do
		if not fs.isFile("src/server/Services/" .. name .. ".luau") then
			table.insert(missing, name)
		end
	end
	check(#missing == 0, "Cada servicio de la lista existe" .. (if #missing > 0 then ": faltan " .. table.concat(missing, ", ") else ""))
	-- Ningún paso síncrono fuera de Boot.step: las llamadas que quedan sueltas son require/task.spawn/Boot
	local loose = {}
	for line in string.gmatch(mainSrc, "[^\n]+") do
		if string.match(line, "^[%a_][%w_%.]*[%(:]") and not string.match(line, "^Boot%.") and not string.match(line, "^task%.spawn") and not string.match(line, "^print") and not string.match(line, "^warn") and not string.match(line, "^workspace:SetAttribute") then
			table.insert(loose, line)
		end
	end
	check(#loose == 0, "En Main no queda ningún paso sin proteger" .. (if #loose > 0 then ": " .. table.concat(loose, " | ") else ""))

	-- Un mundo y unos servicios de mentira
	local ws = attrs("Workspace")
	local town = attrs("Town")
	ws.__children.Town = town
	function ws:GetDescendants()
		return {}
	end
	local called: { string } = {}
	local clockStarted = 0
	local function token(kind: string, name: string): any
		return { __kind = kind, __name = name }
	end
	local folderMeta = {}
	folderMeta.__index = function(self, key)
		return token(rawget(self, "__kind"), key)
	end
	local servicesFolder = setmetatable({ __kind = "Service" }, folderMeta)
	local worldFolder = setmetatable({ __kind = "World" }, folderMeta)
	local BootMain = loadModule("src/server/Boot.luau", { workspace = ws, task = task, warn = fakeWarn })
	BootMain.StepTimeout = 0.3
	local world = {
		TerrainBuilder = { build = function()
			error("el terreno se rompe")
		end, removeGroundPart = function() end },
		TownBuilder = { build = function() end, roads = function()
			return {}
		end },
		Kit = setmetatable({ __kind = "World" }, folderMeta),
	}
	local stub = function(name: string): any
		if world[name] then
			return world[name]
		end
		if name == "Decor" then
			return { dressTown = function() end }
		elseif name == "Polish" then
			return { SurfaceVersion = 0, surfaces = function() end }
		elseif name == "Roads" then
			return { segments = function()
				return {}
			end, Kinds = {} }
		elseif name == "Ambient" then
			return { publish = function() end }
		end
		return { start = function() end, build = function() end }
	end
	local fakeRequire = function(target: any): any
		if target == "BOOT" then
			return BootMain
		end
		if type(target) == "table" and target.__kind == "World" then
			return stub(target.__name)
		end
		if type(target) == "table" and target.__kind == "Service" then
			local name = target.__name
			return { init = function()
				table.insert(called, name)
				if name == "OnboardingService" then
					error("un servicio se rompe")
				elseif name == "BusinessService" then
					task.wait(1e6) -- se queda colgado
				end
			end, startClock = function()
				clockStarted += 1
				ws:SetAttribute("ClockRunning", true)
			end }
		end
		error("require sin simular: " .. tostring(target))
	end
	local serverFolder = { Services = servicesFolder, World = worldFolder, Boot = "BOOT" }
	local fakeGame = {
		GetService = function(_, name)
			return { Shared = {} }
		end,
	}
	local env = {
		script = { Parent = serverFolder },
		workspace = ws,
		game = fakeGame,
		require = fakeRequire,
		task = task,
		warn = fakeWarn,
		print = function() end,
	}
	local mainFn = luau.load(mainSrc, { debugName = "Main.server", environment = setmetatable(env, { __index = _G }) })
	local t0 = os.clock()
	local crashed = nil
	task.spawn(function()
		local ok, err = pcall(mainFn)
		if not ok then
			crashed = tostring(err)
		end
	end)
	while ws:GetAttribute("ServerReady") ~= true and os.clock() - t0 < 30 and not crashed do
		task.wait(0.05)
	end
	check(crashed == nil, "Main no se cae" .. (if crashed then ": " .. crashed else ""))
	check(ws:GetAttribute("ServerReady") == true, ("workspace.ServerReady = true al terminar (%.1f s)"):format(os.clock() - t0))
	check(warned("el terreno se rompe"), "El terreno que falla se avisa y se sigue")
	local inOrder = #called == #order
	for i, name in order do
		if called[i] ~= name then
			inOrder = false
			break
		end
	end
	check(inOrder, ("Se arrancan TODOS los servicios, en orden (%d de %d), aunque uno falle y otro se cuelgue"):format(#called, #order))
	check(warned("Error iniciando OnboardingService") and warned("BusinessService sigue sin terminar"), "Se avisa del que falla y del que se cuelga")
	check(clockStarted == 1 and ws:GetAttribute("ClockRunning") == true, "WorldService no puso el reloj: Main lo pone en marcha igual")
end

---------------------------------------------------------------------
print("\n▶ 3. WorldService: el reloj corre desde el primer momento")
---------------------------------------------------------------------
do
	local src = fs.readFile("src/server/Services/WorldService.luau")
	local initAt = string.find(src, "function WorldService.init()", 1, true)
	local startAt = initAt and string.find(src, "WorldService.startClock()", initAt, true)
	local lightAt = initAt and string.find(src, "pcall(setupLighting)", initAt, true)
	check(startAt and lightAt and startAt < lightAt, "init pone en marcha el reloj ANTES de todo lo demás (luz, lugares, ferris…)")
	check(string.find(src, 'workspace:SetAttribute("ClockRunning", true)', 1, true) ~= nil, "El reloj avisa de que corre (atributo ClockRunning)")
	-- El reloj de verdad con un Heartbeat de mentira
	local heartbeat = signal()
	local lighting = { ClockTime = 8 }
	local changed = signal()
	function lighting:GetPropertyChangedSignal()
		return changed
	end
	setmetatable(lighting, { __newindex = function(t, k, v)
		rawset(t, k, v)
	end })
	local ws = attrs("Workspace")
	local players = {}
	local player = attrs("Kid")
	player:SetAttribute("LifeStage", "Nino")
	local fakeConfig = { DayLengthMinutes = 20, SchoolDay = { Start = 9, End = 17, ClockSpeed = 0 }, StartClockTime = 8 }
	local services = {
		Lighting = lighting,
		RunService = { Heartbeat = heartbeat },
		Players = { GetPlayers = function()
			return players
		end, PlayerRemoving = signal() },
		CollectionService = {},
		ReplicatedStorage = { Shared = { Config = "CONFIG", MapInfo = "MAPINFO" } },
	}
	local env = {
		game = { GetService = function(_, n)
			return services[n] or {}
		end },
		workspace = ws,
		task = task,
		warn = fakeWarn,
		script = { Parent = { Parent = { World = { Npc = "NPC" } } } },
		Color3 = roblox.Color3,
		Vector3 = roblox.Vector3,
		CFrame = roblox.CFrame,
		Enum = roblox.Enum,
		Instance = { new = function()
			return {}
		end },
		require = function(t)
			if t == "CONFIG" then
				return fakeConfig
			end
			return setmetatable({}, { __index = function()
				return function() end
			end })
		end,
	}
	local ok, World = pcall(loadModule, "src/server/Services/WorldService.luau", env)
	check(ok and type(World) == "table" and type(World.startClock) == "function", "WorldService.startClock existe" .. (if not ok then ": " .. tostring(World) else ""))
	if ok and type(World) == "table" then
		World.startClock()
		World.startClock() -- (dos veces: un solo reloj)
		check(heartbeat:Count() == 1, "startClock pone UN reloj aunque se llame dos veces")
		for _ = 1, 200 do
			heartbeat:Fire(0.25) -- 50 s reales = 1 hora de juego
		end
		check(lighting.ClockTime > 8.9, ("Avanza: tras 50 s reales son las %.2f (antes 8:00)"):format(lighting.ClockTime))
		table.insert(players, player)
		for _ = 1, 400 do
			heartbeat:Fire(0.25)
		end
		check(lighting.ClockTime > 9.5, ("Con un niño en horario de cole y ClockSpeed = 0 NO se para (%.2f)"):format(lighting.ClockTime))
		check(ws:GetAttribute("ClockRunning") == true, "ClockRunning = true")
	end
end

---------------------------------------------------------------------
print("\n▶ 4. Cliente: pantalla de carga y esperas sin rendirse")
---------------------------------------------------------------------
do
	local ws = attrs("Workspace")
	local lp = attrs("Jugador")
	local env = {
		workspace = ws,
		task = task,
		game = { GetService = function(_, n)
			if n == "Players" then
				return { LocalPlayer = lp }
			end
			return {}
		end },
	}
	local Gate = loadModule("src/client/UI/LoadingGate.luau", env)
	check(Gate.missing(nil, 0) == "Preparando la ciudad…", "Servidor arrancando: «Preparando la ciudad…»")
	ws:SetAttribute("ServerReady", true)
	check(Gate.missing(nil, 0) == "Cargando tu partida…", "Servidor listo pero sin tu partida: «Cargando tu partida…» (nunca los valores por defecto)")
	lp:SetAttribute("DataLoaded", true)
	check(Gate.missing(0, 1) == "Preparando tu historia…", "Partida cargada, falta la historia: se espera")
	check(Gate.missing(0, Gate.STORY_WAIT + 1) == nil, "…como mucho STORY_WAIT s (luego el panel de misiones sigue pidiéndola)")
	lp:SetAttribute("StoryReady", true)
	check(Gate.missing(0, 1) == nil, "Con todo listo, a jugar")
	local mainClient = fs.readFile("src/client/Main.client.luau")
	local gateAt = string.find(mainClient, "LoadingGate", 1, true)
	local hudAt = string.find(mainClient, "Hud.init(", 1, true)
	check(gateAt and hudAt and gateAt < hudAt, "El cliente pone la pantalla de carga lo primero (antes que el HUD)")

	local ws2 = attrs("Workspace")
	local SW = loadModule("src/client/UI/ServerWait.luau", { workspace = ws2, task = task, game = {} })
	SW.POLL = 0.02
	SW.GRACE = 0.2
	local parent = attrs("Remotes")
	local got, done = nil, false
	task.spawn(function()
		got = SW.child(parent, "Combate")
		done = true
	end)
	task.wait(0.5)
	check(not done, "Mientras el servidor arranca, ServerWait sigue esperando (antes: 30-60 s y se rendía)")
	parent.__children.Combate = { Name = "Combate" }
	task.wait(0.1)
	check(done and got and got.Name == "Combate", "Llega el remoto (aunque tarde): se usa")
	local got2, done2 = "x", false
	ws2:SetAttribute("ServerReady", true)
	task.spawn(function()
		got2 = SW.child(parent, "NoExiste")
		done2 = true
	end)
	task.wait(0.5)
	check(done2 and got2 == nil, "Servidor ya listo y no aparece (su servicio falló): nil tras el margen")
	-- Ningún controlador vuelve a rendirse a los 10-60 s con lo que crea el servidor al arrancar
	local runtime = { "StoryScenes", "Hospital", "Wanted", "Happening", "Damage", "Interior", "Pets", "Justice", "Career", "MapZones", "MapLandmarks", "CityErrands", "StageSets", "Debug", "Combat", "Tester", "Update", "Roads" }
	local bad = {}
	for _, dir in { "src/client/Controllers", "src/client/UI" } do
		for _, file in fs.readDir(dir) do
			if string.match(file, "%.luau$") then
				local text = fs.readFile(dir .. "/" .. file)
				for _, name in runtime do
					if string.find(text, 'WaitForChild("' .. name .. '", ', 1, true) then
						table.insert(bad, file .. ":" .. name)
					end
				end
			end
		end
	end
	check(#bad == 0, "Nada de WaitForChild con tiempo para lo que crea el servidor (usa UI/ServerWait)" .. (if #bad > 0 then ": " .. table.concat(bad, ", ") else ""))
end

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
process.exit(0)
