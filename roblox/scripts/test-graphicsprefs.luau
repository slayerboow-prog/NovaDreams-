-- Prueba: los ✨ Gráficos elegidos se guardan con la partida y vuelven al entrar (UI/Perf +
-- Services/SettingsService), y el modo «Auto» nunca pisa un nivel fijo.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-graphicsprefs.luau

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local failed = 0
local function check(ok: any, label: string)
	if ok then
		print("  ✅ " .. label)
	else
		failed += 1
		print("  ❌ " .. label)
	end
end

local function load(path: string, env: { [string]: any }): any
	setmetatable(env, { __index = _G })
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end

local function signal()
	local fns = {}
	return {
		Connect = function(_, fn)
			table.insert(fns, fn)
			return { Disconnect = function() end }
		end,
		Fire = function(_, ...)
			for _, fn in fns do
				fn(...)
			end
		end,
	}
end

-- Un jugador con atributos (como los de Roblox: avisan al cambiar)
local function newPlayer(name: string)
	local attrs = {}
	local signals = {}
	local p = { Name = name }
	function p:GetAttribute(k)
		return attrs[k]
	end
	function p:SetAttribute(k, v)
		if attrs[k] == v then
			return
		end
		attrs[k] = v
		if signals[k] then
			signals[k]:Fire()
		end
	end
	function p:GetAttributeChangedSignal(k)
		signals[k] = signals[k] or signal()
		return signals[k]
	end
	return p
end

local Graphics = load("src/shared/Graphics.luau", {})
local GRAPHICS = { __module = "Graphics" }
local DATA = { __module = "DataService" }

---------------------------------------------------------------------
-- Servidor: SettingsService guarda y devuelve lo elegido
---------------------------------------------------------------------
local saves: { [any]: { [string]: any } } = {}
local loadedFns = {}
local DataMock = {
	get = function(player)
		return saves[player]
	end,
	onLoaded = function(fn)
		table.insert(loadedFns, fn)
	end,
}
local serverRemote = { Name = "GraphicsChoice", OnServerEvent = signal() }
local serverRemotes = {
	FindFirstChild = function(_, n)
		return if n == "GraphicsChoice" then serverRemote else nil
	end,
}
local fakeClock = 0
local Settings = load("src/server/Services/SettingsService.luau", {
	script = { Parent = { DataService = DATA } },
	game = {
		GetService = function(_, name)
			if name == "Players" then
				return { PlayerRemoving = signal() }
			end
			return {
				Shared = { Graphics = GRAPHICS },
				WaitForChild = function()
					return serverRemotes
				end,
			}
		end,
	},
	require = function(m)
		if m == GRAPHICS then
			return Graphics
		elseif m == DATA then
			return DataMock
		end
		error("require inesperado")
	end,
	os = setmetatable({
		clock = function()
			return fakeClock
		end,
	}, { __index = os }),
})
Settings.init()

print("Servidor: se guarda con la partida")
local server = newPlayer("Dueño")
saves[server] = { Money = 0 } -- (partida vieja, sin Graphics)
for _, fn in loadedFns do
	fn(server, saves[server])
end
check(server:GetAttribute("GraphicsChoice") == "Auto", "jugador nuevo (o partida vieja): Auto")
fakeClock += 1
serverRemote.OnServerEvent:Fire(server, "Choice", "High")
check(saves[server].Graphics == "High" and server:GetAttribute("GraphicsChoice") == "High", "elegir Alto lo guarda en la partida")
fakeClock += 1
serverRemote.OnServerEvent:Fire(server, "Choice", "Ultra")
fakeClock += 1
serverRemote.OnServerEvent:Fire(server, "Choice", { "High" })
check(saves[server].Graphics == "High", "algo que no es Auto/Bajo/Medio/Alto no se guarda")
fakeClock += 1
serverRemote.OnServerEvent:Fire(server, "TipSeen")
check(saves[server].GraphicsTipSeen == true, "el consejo de la calidad de Roblox queda visto")
-- Vuelve a entrar (otro servidor): la partida guardada trae Alto
local again = newPlayer("Dueño")
saves[again] = { Graphics = saves[server].Graphics, GraphicsTipSeen = saves[server].GraphicsTipSeen }
for _, fn in loadedFns do
	fn(again, saves[again])
end
check(again:GetAttribute("GraphicsChoice") == "High" and again:GetAttribute("GraphicsTipSeen") == true, "al volver a entrar, vuelve Alto (atributo GraphicsChoice)")
local dataSrc = fs.readFile("src/server/Services/DataService.luau")
check(dataSrc:find('Graphics = "Auto"', 1, true) and dataSrc:find("fresh.Graphics = data.Graphics", 1, true), "DataService: Auto por defecto y se conserva en una vida nueva")
check(fs.readFile("src/server/Main.server.luau"):find('"SettingsService"', 1, true) ~= nil and fs.readFile("default.project.json"):find('"GraphicsChoice"', 1, true) ~= nil, "SettingsService arranca y el remoto GraphicsChoice existe")

---------------------------------------------------------------------
-- Cliente: UI/Perf (un móvil con la calidad de Roblox baja)
---------------------------------------------------------------------
local function bootClient(opts: { Quality: number?, Attr: string?, Mobile: boolean })
	local player = newPlayer("Cliente")
	if opts.Attr then
		player:SetAttribute("GraphicsChoice", opts.Attr)
	end
	local heartbeat = signal()
	local fired = {}
	local clientRemote = {
		FireServer = function(_, ...)
			table.insert(fired, { ... })
		end,
	}
	local AUTO = { Name = "Automatic" }
	local services = {
		Players = { LocalPlayer = player },
		RunService = { Heartbeat = heartbeat },
		UserInputService = { TouchEnabled = opts.Mobile, KeyboardEnabled = not opts.Mobile },
		ReplicatedStorage = {
			Shared = { Graphics = GRAPHICS },
			FindFirstChild = function(_, n)
				return if n == "Remotes"
					then {
						FindFirstChild = function(_, m)
							return if m == "GraphicsChoice" then clientRemote else nil
						end,
					}
					else nil
			end,
		},
	}
	local delayed = {}
	local Perf = load("src/client/UI/Perf.luau", {
		game = {
			GetService = function(_, name)
				return services[name]
			end,
		},
		UserSettings = function()
			return {
				GetService = function()
					return { SavedQualityLevel = if opts.Quality then { Value = opts.Quality } else AUTO }
				end,
			}
		end,
		Enum = { SavedQualitySetting = { Automatic = AUTO } },
		require = function(m)
			if m == GRAPHICS then
				return Graphics
			end
			error("require inesperado")
		end,
		task = {
			spawn = function(fn, ...)
				fn(...)
			end,
			defer = function(fn, ...)
				fn(...)
			end,
			delay = function(_, fn, ...)
				table.insert(delayed, { fn, table.pack(...) })
			end,
		},
	})
	local function run(seconds: number, fps: number)
		for _ = 1, math.floor(seconds * fps) do
			heartbeat:Fire(1 / fps)
		end
	end
	return Perf, player, fired, run, delayed
end

print("Cliente: lo guardado vuelve antes que el Auto")
do
	-- Jugador nuevo en un móvil con la calidad de Roblox en 1: empieza en Auto · Medio (no en Bajo)
	local Perf, player = bootClient({ Mobile = true, Quality = 1 })
	check(Perf.tierName() == "Medium" and Perf.choice() == "Auto", ("móvil con la calidad de Roblox baja: empieza en Auto · Medio (%s)"):format(Perf.tierName()))
	player:SetAttribute("GraphicsChoice", "Auto")
	check(Perf.tierName() == "Medium", "y lo guardado (Auto) lo deja en Medio")
end
do
	-- Lo dejó en Alto: al entrar el servidor manda Alto unos segundos después y el Auto no lo toca
	local Perf, player, fired, run = bootClient({ Mobile = true, Quality = 1 })
	Perf.startAuto()
	run(3, 20) -- (cargando: aún no ha llegado la partida, y el Auto no empieza)
	check(Perf.tierName() == "Medium" and not Perf.restored(), "mientras llega la partida, el Auto espera")
	player:SetAttribute("GraphicsChoice", "High")
	check(Perf.tierName() == "High" and Perf.choice() == "High", "llega lo guardado: Alto (fijo)")
	check(player:GetAttribute("GraphicsTier") == "High", "el atributo GraphicsTier dice Alto")
	run(300, 12) -- (5 minutos a 12 fps: el Auto, si mandara, bajaría a Bajo)
	check(Perf.tierName() == "High", "con un nivel fijo, el Auto no lo baja nunca (5 min a 12 fps)")
	check(#fired == 0, "restaurar no vuelve a guardar")
end
do
	-- Lo guardado ya está puesto cuando arranca el cliente (atributo puesto antes)
	local Perf = bootClient({ Mobile = true, Quality = 2, Attr = "Low" })
	check(Perf.tierName() == "Low" and Perf.choice() == "Low", "si lo guardado ya estaba, se pone al cargar (Bajo fijo)")
end
do
	-- El jugador elige: se guarda; lo que llegue tarde de la partida no lo pisa
	local Perf, player, fired, _, delayed = bootClient({ Mobile = true, Quality = 2 })
	Perf.setChoice("High")
	check(#fired == 1 and fired[1][1] == "Choice" and fired[1][2] == "High", "elegir Alto lo manda guardar (remoto GraphicsChoice)")
	player:SetAttribute("GraphicsChoice", "Low")
	check(Perf.tierName() == "High", "lo guardado que llega tarde no pisa lo que acaba de elegir")
	local toasts = {}
	Perf.announce(function(_, text)
		table.insert(toasts, text)
	end)
	for _, d in delayed do
		d[1](table.unpack(d[2], 1, d[2].n))
	end
	check(toasts[1] and toasts[1]:find("Alto:", 1, true) and toasts[1]:find("sombras", 1, true), ("aviso: qué cambia («%s»)"):format(tostring(toasts[1])))
	check(toasts[2] and toasts[2]:find("Calidad de gráficos", 1, true), "con la calidad de Roblox baja, el consejo de subirla")
	check(fired[2] and fired[2][1] == "TipSeen", "el consejo se apunta como visto (se guarda)")
	local more = 0
	Perf.tipIfNeeded(function()
		more += 1
	end)
	check(more == 0, "y no vuelve a salir")
	Perf.setChoice("Ultra" :: any)
	check(Perf.choice() == "High", "una opción que no existe no cambia nada")
end
do
	-- Auto sigue funcionando (sin partida guardada: empieza tras la espera)
	local Perf, _, _, run = bootClient({ Mobile = false })
	Perf.startAuto()
	check(Perf.tierName() == "High", "ordenador: empieza en Alto")
	run(60, 20)
	check(Perf.tierName() == "Medium", ("en Auto, a 20 fps baja a Medio (%s)"):format(Perf.tierName()))
end

print("")
if failed > 0 then
	print(("❌ %d comprobación(es) fallan"):format(failed))
	process.exit(1)
end
print("✅ Los gráficos se guardan, vuelven al entrar y el Auto no pisa un nivel fijo")
