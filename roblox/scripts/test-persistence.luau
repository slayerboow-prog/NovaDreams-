-- Prueba de que la partida SE GUARDA de verdad y vuelve igual al entrar en OTRO servidor (Lune).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-persistence.luau        (~1 min)
--
-- Por qué existe: el dueño entraba, jugaba, salía… y al volver «es como si empezase otra vez»
-- (Lunes 1 de enero · Día 1, la misma misión a 0/3, el mismo sitio). Comprueba:
--   1. shared/SaveCheck: lo que el DataStore de Roblox rechaza (Vector3, CFrame, Color3, NaN,
--      infinitos, tablas con claves numéricas sueltas o mezcladas, texto no UTF-8, ciclos,
--      funciones, instancias) se corrige; las claves numéricas vuelven a ser números al cargar.
--   2. Una partida de alguien que ha jugado MUCHO (historia, biografía, pase, cosméticos, archivo de
--      temporadas, barcos, garaje, tester, cargadores…) cabe de sobra en 4 MB; una hinchada se recorta.
--   3. DataService de verdad con un DataStore de mentira ESTRICTO (rechaza como Roblox lo que no se
--      puede guardar y lo que pasa de 4 MB): jugar → cambiar paso de misión / sitio / día → salir →
--      entrar en un servidor NUEVO → todo igual. Con valores rotos dentro, se guarda igual (corregido)
--      y avisa. Si el DataStore falla, reintenta; si falla siempre, avisa en la consola con el motivo
--      y al tester/dueño con un aviso en pantalla («⚠ No se pudo guardar la partida»), una vez.
--   4. CalendarService: el día de tu vida se guarda; un servidor vacío sigue tu calendario (día y
--      hora); con más gente, cada uno cuenta su día; al pasar la noche sube.
--   5. PositionService: vuelves donde lo dejaste; nadando o en el aire no se apunta (se queda el
--      último sitio seguro); si donde estabas ya no hay suelo (o es agua), a tu cama.
--   6. La historia (LifeStoryService con StoryHarness): una misión a medias (grupo de tareas con una
--      hecha) sigue igual al volver, el día normal del cole ya hecho hoy NO se repite (LoopDay en días
--      de tu vida) y un grupo de tareas repartido por la ciudad NO te teletransporta al entrar.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local task = require("@lune/task")

local Vector3, CFrame, Color3, Enum = roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Enum

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

---------------------------------------------------------------------
-- Las reglas del DataStore de Roblox, escritas aparte (para no probar SaveCheck consigo mismo)
---------------------------------------------------------------------
local function robloxRejects(value: any): string?
	local seen = {}
	local function walk(v: any, path: string): string?
		local t = typeof(v)
		if t == "nil" or t == "boolean" then
			return nil
		elseif t == "number" then
			if v ~= v or v == math.huge or v == -math.huge then
				return path .. ": número no válido"
			end
			return nil
		elseif t == "string" then
			return if utf8.len(v) then nil else path .. ": texto no UTF-8"
		elseif t == "table" then
			if seen[v] then
				return path .. ": ciclo"
			end
			seen[v] = true
			local count, strings, ints, maxInt = 0, 0, 0, 0
			for k in v do
				count += 1
				if type(k) == "string" then
					if not utf8.len(k) then
						return path .. ": clave no UTF-8"
					end
					strings += 1
				elseif type(k) == "number" and k == math.floor(k) and k >= 1 then
					ints += 1
					maxInt = math.max(maxInt, k)
				else
					return path .. ": clave " .. typeof(k)
				end
			end
			if strings > 0 and ints > 0 then
				return path .. ": tabla mezclada"
			end
			if ints > 0 and maxInt ~= count then
				return path .. ": lista con huecos"
			end
			for k, item in v do
				local err = walk(item, path .. "." .. tostring(k))
				if err then
					return err
				end
			end
			seen[v] = nil
			return nil
		end
		return path .. ": " .. t .. " no se puede guardar"
	end
	return walk(value, "data")
end

---------------------------------------------------------------------
-- Un Roblox de mentira (lo justo para DataService, CalendarService y PositionService)
---------------------------------------------------------------------
local function signal()
	local handlers = {}
	return {
		Connect = function(_, fn)
			table.insert(handlers, fn)
			return { Disconnect = function() end }
		end,
		Fire = function(_, ...)
			for _, fn in table.clone(handlers) do
				task.spawn(fn, ...)
			end
		end,
		Wait = function()
			return nil
		end,
	}
end

local function instance(className: string, name: string?): any
	local self: any = { ClassName = className, Name = name or className, __children = {}, __attributes = {}, __attrSignals = {} }
	function self:FindFirstChild(child)
		for _, c in self.__children do
			if c.Name == child then
				return c
			end
		end
		return nil
	end
	function self:WaitForChild(child)
		return self:FindFirstChild(child) or error("sin " .. tostring(child))
	end
	function self:FindFirstChildOfClass(class)
		for _, c in self.__children do
			if c.ClassName == class then
				return c
			end
		end
		return nil
	end
	function self:GetAttribute(key)
		return self.__attributes[key]
	end
	function self:SetAttribute(key, value)
		self.__attributes[key] = value
		if self.__attrSignals[key] then
			self.__attrSignals[key]:Fire()
		end
	end
	function self:GetAttributeChangedSignal(key)
		self.__attrSignals[key] = self.__attrSignals[key] or signal()
		return self.__attrSignals[key]
	end
	function self:IsA(other)
		return other == className or (other == "BasePart" and className == "Part")
	end
	function self:FindFirstAncestorOfClass()
		return nil
	end
	return setmetatable(self, {
		__newindex = function(t, key, value)
			if key == "Parent" and value then
				table.insert(value.__children, t)
			end
			rawset(t, key, value)
		end,
	})
end

-- DataStore de mentira ESTRICTO, compartido por todos los "servidores": guarda JSON como Roblox
local stored: { [string]: string } = {}
local storeFailures = 0 -- cuántas llamadas seguidas van a fallar (como un 502 de Roblox)
local storeCalls = 0
local fakeStore = {
	UpdateAsync = function(_, key, fn)
		storeCalls += 1
		if storeFailures > 0 then
			storeFailures -= 1
			error("502: API Services rejected request with error. HTTP 500 (Internal Server Error)")
		end
		local old = if stored[key] then serde.decode("json", stored[key]) else nil
		local result = fn(old)
		if result ~= nil then
			local bad = robloxRejects(result)
			if bad then
				error("104: Cannot store value in data store: " .. bad)
			end
			local json = serde.encode("json", result)
			if #json > 4194304 then
				error("105: Serialized value exceeds 4MB limit.")
			end
			stored[key] = json
		end
		return result
	end,
}

-- Suelo de mentira: y = 0 en todas partes salvo el "lago" (x > 5000: agua) y el "agujero"
-- (x < -5000: nada)
local groundPart = instance("Part", "Suelo")
groundPart.CanCollide = true
local fakeWorkspace = instance("Workspace", "Workspace")
fakeWorkspace.FallenPartsDestroyHeight = -500
function fakeWorkspace:Raycast(origin, direction)
	if origin.X < -5000 then
		return nil
	end
	local y = 0
	if origin.Y < y or origin.Y + direction.Y > y then
		return nil
	end
	return {
		Position = Vector3.new(origin.X, y, origin.Z),
		Instance = groundPart,
		Material = if origin.X > 5000 then Enum.Material.Water else Enum.Material.Grass,
		Normal = Vector3.new(0, 1, 0),
	}
end

local log: { string } = {}
local function logged(fragment: string): boolean
	for _, line in log do
		if string.find(line, fragment, 1, true) then
			return true
		end
	end
	return false
end

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

local testerMock = { isTester = function(player)
	return player.IsTester == true
end }

-- Un "servidor": su propio juego de mentira (JobId), sus módulos recién cargados y sus jugadores
local function newServer(jobId: string)
	local server: any = { JobId = jobId, Players = {}, Toasts = {} }
	local replicated = instance("ReplicatedStorage")
	local remotes = instance("Folder", "Remotes")
	remotes.Parent = replicated
	rawset(replicated, "Remotes", remotes) -- (en Roblox, los hijos se leen como campos)
	local newLife = instance("RemoteEvent", "NewLife")
	newLife.OnServerEvent = signal()
	newLife.Parent = remotes
	local notify = instance("RemoteEvent", "Notify")
	notify.FireClient = function(_, player, kind, text)
		table.insert(server.Toasts, { Player = player, Kind = kind, Text = text })
	end
	notify.Parent = remotes
	replicated.Shared = node("src/shared")
	local lighting = { ClockTime = 14 }
	server.Lighting = lighting
	local playerAdded, playerRemoving = signal(), signal()
	server.PlayerAdded, server.PlayerRemoving = playerAdded, playerRemoving
	local services = {
		ReplicatedStorage = replicated,
		DataStoreService = { GetDataStore = function()
			return fakeStore
		end },
		Players = { PlayerAdded = playerAdded, PlayerRemoving = playerRemoving, GetPlayers = function()
			return table.clone(server.Players)
		end },
		RunService = { IsStudio = function()
			return false
		end },
		Lighting = lighting,
	}
	local fakeGame = {
		JobId = jobId,
		GetService = function(_, name)
			return services[name] or error("Servicio sin simular: " .. name)
		end,
		BindToClose = function() end,
	}
	-- Mundo: cada servidor nuevo empieza en el día 1 (como WorldService)
	fakeWorkspace.__attributes.Day = 1
	fakeWorkspace.__attrSignals = {}
	local cache = {}
	local function load(path: string): any
		if path == "src/server/Services/TesterService" then
			return testerMock
		end
		if cache[path] ~= nil then
			return cache[path]
		end
		local env = setmetatable({
			script = node(path),
			require = function(target)
				return load(rawget(target, "__path"))
			end,
			game = fakeGame,
			workspace = fakeWorkspace,
			task = task,
			Vector3 = Vector3,
			Vector2 = roblox.Vector2,
			Color3 = Color3,
			CFrame = CFrame,
			Enum = Enum,
			RaycastParams = { new = function()
				return { FilterDescendantsInstances = {} }
			end },
			Instance = { new = function(className)
				return instance(className)
			end },
			warn = function(...)
				local parts = {}
				for _, v in { ... } do
					table.insert(parts, tostring(v))
				end
				table.insert(log, table.concat(parts, " "))
			end,
		}, { __index = _G })
		local result = luau.load(fs.readFile(path .. ".luau"), { debugName = path, environment = env })()
		cache[path] = result
		return result
	end
	server.load = load
	server.DataService = load("src/server/Services/DataService")
	server.CalendarService = load("src/server/Services/CalendarService")
	server.PositionService = load("src/server/Services/PositionService")
	server.DataService.init()
	server.CalendarService.init()
	server.PositionService.init()
	return server
end

local function waitFor(condition: () -> boolean, seconds: number): boolean
	local since = os.clock()
	while os.clock() - since < seconds do
		if condition() then
			return true
		end
		task.wait(0.05)
	end
	return condition()
end

-- Un jugador con su personaje (raíz, humanoide) en el sitio dado
local function newPlayer(server, userId: number, name: string, at: Vector3?): any
	local p = instance("Player", name)
	p.UserId = userId
	p.Parent = instance("Players")
	p.Kick = function(self, reason)
		self.Kicked = reason
	end
	p.CharacterAdded = signal()
	p.RequestStreamAroundAsync = function() end
	local character = instance("Model", name)
	local root = instance("Part", "HumanoidRootPart")
	root.Position = at or Vector3.new(0, 3, 0)
	root.CFrame = CFrame.new(root.Position)
	root.AssemblyLinearVelocity = Vector3.zero
	root.Parent = character
	local humanoid = instance("Humanoid", "Humanoid")
	humanoid.Health = 100
	humanoid.State = Enum.HumanoidStateType.Running
	humanoid.FloorMaterial = Enum.Material.Grass
	humanoid.SeatPart = nil
	function humanoid:GetState()
		return self.State
	end
	humanoid.Parent = character
	function character:PivotTo(cf)
		root.Position = cf.Position
		root.CFrame = cf
		p.PivotedTo = cf.Position
	end
	p.Character = character
	p.Root, p.Humanoid = root, humanoid
	return p
end

local function join(server, p)
	table.insert(server.Players, p)
	server.PlayerAdded:Fire(p)
	return waitFor(function()
		return server.DataService.get(p) ~= nil and p:GetAttribute("SpawnReady") == true
	end, 8)
end

local function leave(server, p)
	p.Parent = nil
	local i = table.find(server.Players, p)
	if i then
		table.remove(server.Players, i)
	end
	server.PlayerRemoving:Fire(p)
	-- (el guardado de salida termina cuando ya no tiene perfil)
	return waitFor(function()
		return server.DataService.get(p) == nil
	end, 20)
end

local function savedOf(userId: number): any
	local json = stored["Player_" .. userId]
	return json and serde.decode("json", json)
end

---------------------------------------------------------------------
print("\n▶ 1. SaveCheck: lo que el DataStore rechaza se corrige")
---------------------------------------------------------------------
local Shared = newServer("arranque") -- (para cargar los módulos compartidos con el mismo entorno)
local SaveCheck = Shared.load("src/shared/SaveCheck")
do
	local cyclic = { A = 1 }
	cyclic.Self = cyclic
	local broken = {
		Money = 0 / 0,
		Big = math.huge,
		Pos = Vector3.new(1, 2, 3),
		Look = CFrame.new(4, 5, 6),
		Tint = Color3.new(1, 0.5, 0),
		Mat = Enum.Material.Grass,
		Fn = function() end,
		Inst = { ClassName = "Part", __props = {} },
		Sparse = { [1] = "a", [3] = "c" },
		Mixed = { "x", "y", Name = "z" },
		Zero = { [0] = "cero", [1] = "uno" },
		Floats = { [1.5] = true },
		BoolKey = { [true] = 1 },
		Text = "Mar\xC3",
		Cyclic = cyclic,
		List = { 1, 2, 3 },
		Fine = { Lancha = true },
		Empty = {},
	}
	check(robloxRejects(broken) ~= nil, "La partida rota de ejemplo la rechazaría Roblox (" .. tostring(robloxRejects(broken)) .. ")")
	local clean, problems = SaveCheck.sanitize(broken)
	check(robloxRejects(clean) == nil, "Tras SaveCheck.sanitize se puede guardar")
	check(#problems >= 12, ("Se apuntan los problemas con su ruta (%d)"):format(#problems))
	local paths = {}
	for _, problem in problems do
		paths[problem.Path] = problem.Reason
	end
	check(paths.Pos == "Vector3" and paths.Money == "NaN" and paths.Sparse ~= nil and paths["Cyclic.Self"] ~= nil, "…con la ruta de cada uno (Pos: Vector3, Money: NaN, Sparse, Cyclic…)")
	check(clean.Money == 0 and clean.Big == 1e15 and clean.Pos.X == 1 and clean.Pos.Z == 3 and clean.Look.Y == 5, "NaN → 0, infinito → 1e15, Vector3/CFrame → {X,Y,Z}")
	check(clean.Tint.G == 0.5 and clean.Mat == "Grass" and clean.Fn == nil and clean.Inst == nil, "Color3 → {R,G,B}, Enum → nombre; funciones e instancias fuera")
	check(clean.Text == "Mar?" and utf8.len(clean.Text) ~= nil, "Texto no UTF-8 (una tilde cortada por la mitad) → se arregla")
	check(clean.Cyclic.A == 1 and clean.Cyclic.Self == nil, "Una referencia circular se corta")
	check(clean.List[3] == 3 and clean.Fine.Lancha == true, "Lo que estaba bien no cambia")
	-- Pasa por JSON (como el DataStore) y vuelve: las claves numéricas vuelven a ser números
	local back = SaveCheck.restore(serde.decode("json", serde.encode("json", clean)))
	check(back.Sparse[1] == "a" and back.Sparse[3] == "c" and back.Sparse[SaveCheck.NUMKEYS] == nil, "Lista con huecos: al cargar vuelve con t[1] y t[3] (claves numéricas)")
	check(back.Mixed[1] == "x" and back.Mixed[2] == "y" and back.Mixed.Name == "z", "Tabla mezclada: vuelven las dos clases de claves")
	check(back.Zero[0] == "cero" and back.Floats[1.5] == true and next(back.BoolKey) == nil, "Clave 0 y decimales vuelven a ser números (una clave booleana se quita)")
	local json = SaveCheck.encode(clean)
	local decoded = serde.decode("json", json)
	check(decoded.Pos.Y == 2 and decoded.List[2] == 2 and #json == SaveCheck.size(clean), "SaveCheck.encode da JSON válido (y size mide lo mismo)")
	local okEncode = pcall(SaveCheck.encode, { Pos = Vector3.new() })
	check(not okEncode, "SaveCheck.encode se niega a medir algo sin limpiar")
end

---------------------------------------------------------------------
print("\n▶ 2. Una partida de alguien que ha jugado mucho cabe (y una hinchada se recorta)")
---------------------------------------------------------------------
local function longPlayedSave(scale: number): { [string]: any }
	local DataService = Shared.DataService
	local data = DataService.defaultData()
	data.Money = 9999850
	data.Life = { AgeYears = 34, StageSeconds = 12345, Stage = "Adulto" }
	data.Progress = { Level = 100, Xp = 0, Points = 12, Stats = { Salud = 10, Fuerza = 10, Estamina = 10 }, QuestsSeen = {} }
	data.Tester = { Money = true, Bypass = true, RealMoney = 1234 }
	data.Position = { X = 120.5, Y = 4, Z = -88.25, Yaw = 1.2 }
	data.Calendar = { Day = 412, Clock = 17.5 }
	data.WeaponMags = {}
	for i = 1, 30 do
		data.WeaponMags["Arma" .. i] = 12
	end
	data.Vehicles, data.Licenses, data.Fuel, data.Odometer, data.Boats = {}, { A = true, B = true }, {}, {}, {}
	for i = 1, 40 do
		data.Vehicles["Vehiculo" .. i] = true
		data.Fuel["Vehiculo" .. i] = 33.3
		data.Odometer["Vehiculo" .. i] = 1234.5
	end
	for i = 1, 8 do
		data.Boats["Barco" .. i] = true
	end
	data.Garage = {}
	for i = 1, 20 do
		data.Garage["Coche" .. i] = { Paint = "Rojo", Wheels = "Deportivas", Mods = { Spoiler = true, Neon = "Azul" } }
	end
	data.Items, data.Slots = {}, {}
	for i = 1, 36 do
		data.Items["Objeto" .. i] = i
		data.Slots[tostring(i)] = "Objeto" .. i
	end
	local story = {
		Version = 1, Chapters = {}, Active = {}, Completed = {}, Declined = {}, Choices = {}, Flags = {},
		Discovered = {}, NpcMemory = {}, Events = {}, Counters = {}, Traits = {}, Memories = {}, Later = {},
		Clock = 99999, PrologueDone = 1700000000, PrologueResult = "Done", LastSeen = 1700000000, RecapAt = 0,
	}
	for i = 1, 250 do
		story.Completed["Mision_" .. i] = 1700000000 + i
		story.Choices["Mision_" .. i .. ":Decision"] = { V = "Opcion" .. (i % 3), D = i }
		story.Flags["Flag" .. i] = true
	end
	for i = 1, 80 do
		story.NpcMemory["Npc" .. i] = { Rel = 40, Affinity = 3, Facts = { Conocido = 3, Ayudado = 9 } }
		story.Memories["Recuerdo" .. i] = { D = i, T = 1700000000, Q = "Mision_" .. i, S = "Adulto" }
		story.Discovered["Zona" .. i] = true
	end
	for i = 1, 200 * scale do
		table.insert(story.Events, { K = "MOMENT.ALGO_PASO_" .. (i % 50), A = { n = i, who = "Lucía Martínez" }, Y = "Moment", S = "Adulto", D = i, T = 1700000000 + i })
	end
	story.Active.Loco_N1_Cosme = { Step = 2, Count = 0, Started = 1700000000, Kind = "Side", Sub = { ["1"] = true } }
	story.Tracked = "Loco_N1_Cosme"
	data.Story = story
	data.Conduct = { Points = -3, Log = {} }
	for i = 1, 300 * scale do
		table.insert(data.Conduct.Log, { K = "Pelea", Tx = "Te has peleado en el parque", P = -2, T = 1700000000 + i, S = "Adolescente" })
	end
	data.BattlePass = {
		Version = 1, SeasonId = "S3", TotalXp = 123456, Level = 70, PremiumOwned = true,
		ClaimedFree = {}, ClaimedPremium = {}, Missions = { Daily = { Key = 20000, Ids = { "D_Pesca", "D_Gimnasio", "D_X" }, Prog = {}, Rerolls = 0 }, Weekly = { Key = 2900, Ids = {}, Prog = {} }, Season = {}, Story = {}, Event = {} },
		Daily = { Day = 20000, Xp = 300, Sources = { Activity = 100 } }, Zones = {}, Shop = {},
	}
	for level = 1, 100 do
		data.BattlePass.ClaimedFree[tostring(level)] = true
		data.BattlePass.ClaimedPremium[tostring(level)] = true
	end
	data.Cosmetics = { Owned = {}, Equipped = { Gorra = "Gorra_Oro" }, Perks = { DobleXp = true }, Tokens = 40 }
	for i = 1, 300 do
		data.Cosmetics.Owned["Cosmetico" .. i] = { Type = "Ropa", Season = "S" .. (i % 3 + 1), At = 1700000000 }
	end
	data.SeasonArchive = {}
	for s = 1, 2 do
		data.SeasonArchive["S" .. s] = { Level = 100, TotalXp = 200000, PremiumOwned = true, EndedAt = 1700000000 }
	end
	data.Education = { Subjects = {}, Exams = {}, Degrees = { Medicina = { Grade = 8.5, At = 1700000000 } }, Attendance = 300 }
	for i = 1, 40 do
		data.Education.Subjects["Asignatura" .. i] = { Grade = 7.5, Classes = 30 }
		table.insert(data.Education.Exams, { S = "Asignatura" .. i, G = 6.5, T = 1700000000 })
	end
	data.ProcessedReceipts = {}
	for i = 1, 50 do
		table.insert(data.ProcessedReceipts, "recibo-" .. i)
	end
	return data
end

do
	local data = longPlayedSave(1)
	check(robloxRejects(data) == nil, "La partida de mucho jugar se puede guardar tal cual")
	local size = SaveCheck.size((SaveCheck.sanitize(data)))
	check(size < 400000, ("Ocupa %d caracteres: menos del 10%% del límite de 4.194.304"):format(size))
	-- Hinchada (historiales enormes de un fallo que no los recortaba)
	local huge = longPlayedSave(100)
	local clean = SaveCheck.sanitize(huge)
	local before = SaveCheck.size(clean)
	local after, removed = SaveCheck.trim(clean, SaveCheck.SOFT_CHARS)
	check(before > SaveCheck.MAX_CHARS, ("Partida hinchada de prueba: %d caracteres (más de 4 MB)"):format(before))
	check(after <= SaveCheck.SOFT_CHARS and removed > 0, ("SaveCheck.trim la deja en %d (se quitan %d entradas viejas)"):format(after, removed))
	check(clean.Story.Active.Loco_N1_Cosme.Step == 2 and clean.Money == 9999850 and clean.Calendar.Day == 412, "Recortar historiales no toca la historia, el dinero ni el día")
	local log = clean.Conduct.Log
	check(#log > 0 and log[#log].T == 1700000000 + 300 * 100, "Se quitan los más antiguos (el último sigue)")
end

---------------------------------------------------------------------
print("\n▶ 3. Jugar → salir → entrar en OTRO servidor: todo sigue igual")
---------------------------------------------------------------------
local A = Shared -- servidor 1
local ana = newPlayer(A, 101, "Ana", Vector3.new(10, 3, 10))
check(join(A, ana), "Ana entra (servidor 1)")
local data = A.DataService.get(ana)
check(ana:GetAttribute("LifeDay") == 1, "Personaje nuevo: día 1 de su vida")
-- Juega: dinero, misión a medias (grupo de 3 con una hecha), su día, su sitio
data.Money = 5000
data.Story.Active.Loco_N1_Cosme = { Step = 2, Count = 0, Started = os.time(), Kind = "Side", Sub = { ["1"] = true } }
data.Story.Tracked = "Loco_N1_Cosme"
data.Story.Flags.AmigoDeCosme = true
fakeWorkspace:SetAttribute("Day", 2)
fakeWorkspace:SetAttribute("Day", 3)
check(ana:GetAttribute("LifeDay") == 3, "Pasan dos noches en el servidor: su día sube a 3")
A.Lighting.ClockTime = 19.25
ana.Root.Position = Vector3.new(250, 3, -40)
-- Valores que el DataStore rechazaría (antes: no se guardaba NADA)
data.Debug = { Where = Vector3.new(1, 2, 3), Ratio = 0 / 0 }
data.Sparse = { [2] = "dos", [7] = "siete" }
table.clear(log)
check(leave(A, ana), "Ana sale (guardado de salida)")
local saved = savedOf(101)
check(saved ~= nil and saved.SessionLock == nil, "Se ha escrito en el DataStore (y se suelta el bloqueo)")
check(saved and saved.Money == 5000 and saved.Story.Active.Loco_N1_Cosme.Step == 2, "Con el dinero y la misión en su paso")
check(saved and saved.Position and math.abs(saved.Position.X - 250) < 0.01, "Con el sitio donde lo dejó")
check(saved and saved.Calendar and saved.Calendar.Day == 3 and saved.Calendar.Clock == 19.25, "Con su día (3) y la hora (19:15)")
check(saved and saved.Debug.Where.Y == 2 and saved.Debug.Ratio == 0, "Los valores rotos se guardan corregidos (Vector3 → {X,Y,Z}, NaN → 0)")
check(logged("no acepta") and logged("Debug.Where"), "…y la consola avisa de qué estaba mal y dónde")

local B = newServer("servidor-2")
local ana2 = newPlayer(B, 101, "Ana", Vector3.new(0, 3, 0))
check(join(B, ana2), "Ana vuelve a entrar, en un servidor NUEVO")
local data2 = B.DataService.get(ana2)
check(data2.Money == 5000, "El dinero sigue")
local prog = data2.Story.Active.Loco_N1_Cosme
check(prog and prog.Step == 2 and prog.Sub and prog.Sub["1"] == true and data2.Story.Tracked == "Loco_N1_Cosme", "La misión sigue en el paso 2 con el tornillo cogido (1/3), y es la que sigue")
check(data2.Story.Flags.AmigoDeCosme == true, "Las marcas de la historia siguen")
check(ana2:GetAttribute("LifeDay") == 3 and fakeWorkspace:GetAttribute("Day") == 3, "Su día sigue (3): el servidor vacío continúa SU calendario (no «Día 1»)")
check(B.Lighting.ClockTime == 19.25, "…y a la hora a la que lo dejó")
check(ana2.PivotedTo ~= nil and math.abs(ana2.PivotedTo.X - 250) < 0.01 and math.abs(ana2.PivotedTo.Z + 40) < 0.01, "Aparece donde lo dejó (no en la entrada)")
check(data2.Sparse[2] == "dos" and data2.Sparse[7] == "siete" and data2.Sparse[SaveCheck.NUMKEYS] == nil, "La tabla con claves numéricas sueltas vuelve con sus claves numéricas")

-- Otro jugador entra en el mismo servidor: el mundo NO cambia de día, pero él cuenta el suyo
stored.Player_202 = serde.encode("json", { Money = 10, Calendar = { Day = 40, Clock = 8 }, Life = { Stage = "Adulto", AgeYears = 30 }, Stats = { PlaySeconds = 999 } })
local luis = newPlayer(B, 202, "Luis")
check(join(B, luis), "Luis entra en el servidor de Ana")
check(fakeWorkspace:GetAttribute("Day") == 3 and B.Lighting.ClockTime == 19.25, "El mundo sigue en el día de Ana (es de todos)")
check(luis:GetAttribute("LifeDay") == 40, "Luis ve SU día (40)")
fakeWorkspace:SetAttribute("Day", 4)
check(ana2:GetAttribute("LifeDay") == 4 and luis:GetAttribute("LifeDay") == 41, "Pasa la noche: Ana día 4, Luis día 41")

---------------------------------------------------------------------
print("\n▶ 4. Sitio: nadando o en el aire no se apunta; sin suelo, a la cama")
---------------------------------------------------------------------
do
	ana2.Root.Position = Vector3.new(300, 3, 0)
	B.DataService.save(ana2)
	check(B.DataService.get(ana2).Position.X == 300, "En tierra: se apunta")
	ana2.Humanoid.State = Enum.HumanoidStateType.Swimming
	ana2.Humanoid.FloorMaterial = Enum.Material.Water
	ana2.Root.Position = Vector3.new(6000, -2, 0)
	B.DataService.save(ana2)
	check(B.DataService.get(ana2).Position.X == 300, "Nadando: se queda el último sitio en tierra")
	ana2.Humanoid.State = Enum.HumanoidStateType.Freefall
	ana2.Humanoid.FloorMaterial = Enum.Material.Air
	ana2.Root.Position = Vector3.new(320, 80, 0)
	B.DataService.save(ana2)
	check(B.DataService.get(ana2).Position.X == 300, "Cayendo / en el aire: tampoco")
	ana2.Humanoid.State = Enum.HumanoidStateType.Running
	ana2.Humanoid.FloorMaterial = Enum.Material.Grass
	ana2:SetAttribute("InteriorDoor", Vector3.new(77, 3, 77))
	B.DataService.save(ana2)
	check(B.DataService.get(ana2).Position.X == 77, "Dentro de un edificio: se guarda la puerta, en la calle")
	ana2:SetAttribute("InteriorDoor", nil)

	-- Sitio guardado en el agua (de antes de este arreglo) con cama: aparece en la cama
	local d = B.DataService.get(ana2)
	d.Position = { X = 6000, Y = 3, Z = 0 }
	d.SpawnPoint = { X = 40, Y = 3, Z = 40 }
end
leave(B, ana2)
local C = newServer("servidor-3")
local ana3 = newPlayer(C, 101, "Ana")
check(join(C, ana3), "Ana entra en un tercer servidor")
check(ana3.PivotedTo ~= nil and math.abs(ana3.PivotedTo.X - 40) < 0.01, "Lo guardado era agua: aparece en su cama")
check(ana3:GetAttribute("LifeDay") == 4, "Y su día sigue contando (4)")

---------------------------------------------------------------------
print("\n▶ 5. Si el DataStore falla: reintentos y avisos")
---------------------------------------------------------------------
do
	-- Falla dos veces al salir: el tercer intento guarda
	C.DataService.get(ana3).Money = 7777
	storeFailures = 2
	table.clear(log)
	local t0 = os.clock()
	check(leave(C, ana3), "Ana sale con el DataStore fallando dos veces")
	check(savedOf(101).Money == 7777, ("Se guarda al tercer intento (%.1f s)"):format(os.clock() - t0))
	check(logged("NO SE HA GUARDADO") and logged("502"), "La consola dice que falló y por qué (502…)")

	-- Siempre falla: el tester/dueño ve el aviso en pantalla, una sola vez
	local D = newServer("servidor-4")
	local owner = newPlayer(D, 303, "Dueno")
	owner.IsTester = true
	local normal = newPlayer(D, 404, "Normal")
	check(join(D, owner) and join(D, normal), "Entran el dueño (tester) y otro jugador")
	storeFailures = 1000
	D.DataService.save(owner)
	D.DataService.save(owner)
	D.DataService.save(normal)
	local toastsOwner, toastsNormal = 0, 0
	for _, toast in D.Toasts do
		if toast.Player == owner and string.find(toast.Text, "No se pudo guardar la partida", 1, true) then
			toastsOwner += 1
		elseif toast.Player == normal then
			toastsNormal += 1
		end
	end
	check(toastsOwner == 1, "El tester ve «⚠ No se pudo guardar la partida» (una vez, no en cada intento)")
	check(toastsNormal == 0, "A un jugador normal no se le enseña")
	check(type(owner:GetAttribute("SaveError")) == "string" and D.DataService.lastSaveError(owner) ~= nil, "El motivo queda en el atributo SaveError (para el panel de depuración)")
	storeFailures = 0
	check(D.DataService.save(owner) and owner:GetAttribute("SaveError") == nil, "Cuando vuelve a funcionar, guarda y se quita el error")

	-- Una partida demasiado grande: se recorta y se guarda (antes: error 105 y nada guardado)
	local d = D.DataService.get(owner)
	for i = 1, 60000 do
		table.insert(d.Conduct.Log, { K = "Pelea", Tx = "Te has peleado en el parque con alguien muy pesado", P = -2, T = i, S = "Adulto" })
	end
	table.clear(log)
	check(D.DataService.save(owner), "Una partida de más de 4 MB se guarda igual (recortando historiales)")
	check(#stored.Player_303 <= 4194304 and logged("recortan"), ("…ocupa %d caracteres y la consola lo avisa"):format(#stored.Player_303))
	check(#d.Conduct.Log < 60000, "…y también se recorta en memoria (no en cada guardado)")

	-- Bloqueo de otro servidor: no se pisa y se avisa
	local other = serde.decode("json", stored.Player_404)
	other.SessionLock = { JobId = "otro-servidor", Time = os.time() }
	stored.Player_404 = serde.encode("json", other)
	table.clear(log)
	check(not D.DataService.save(normal) and logged("bloqueo"), "Si otro servidor tiene los datos, no se pisan y se avisa")
end

---------------------------------------------------------------------
print("\n▶ 6. La historia de verdad (LifeStoryService): salir a mitad de misión y volver")
---------------------------------------------------------------------
do
	local H = require("./lib/StoryHarness")
	local Service = H.boot()
	local HSaveCheck = H.loadModule(H.ROOT .. "/shared/SaveCheck")
	-- Guardar como el DataStore de verdad: limpiar + JSON (y al cargar, restore)
	local function viaDataStore(saved: string): string
		local clean = HSaveCheck.sanitize(serde.decode("json", saved))
		return HSaveCheck.encode(clean)
	end
	H.defaultAttributes.LifeDay = 12
	local leo = H.newPlayer("Leo", "Nino", 3600)
	task.wait(1)
	local story = H.profiles[leo].Story
	-- A mitad de «El vecino del garaje»: el grupo de las 3 piezas, con el tornillo ya cogido
	story.Active.Loco_N1_Cosme = { Step = 2, Count = 0, Started = os.time(), Kind = "Side", Sub = { ["1"] = true } }
	story.Tracked = "Loco_N1_Cosme"
	-- El día normal del cole ya se hizo HOY (día 12 de su vida)
	story.LoopDay = 12
	story.LoopLife = true
	-- Los sitios de las tres piezas, lejos unos de otros (parque, heladería, colegio)
	local Location = H.mocks[H.ROOT .. "/server/Services/LocationService"]
	local oldResolve = Location.resolve
	local spread = { FuenteParque = Vector3.new(-600, 0, 0), Heladeria = Vector3.new(600, 0, 0), JuegosColegio = Vector3.new(0, 0, 700), GarajeCosme = Vector3.new(0, 0, -700) }
	Location.resolve = function(player, placeId, opts)
		local spot = oldResolve(player, placeId, opts)
		if spread[placeId] then
			spot.Position = spread[placeId]
		end
		return spot
	end
	local saved = viaDataStore(H.leave(leo))
	H.defaultAttributes.LifeDay = 12 -- (vuelve el mismo día de su vida, en otro servidor)
	H.setDay(1) -- el servidor nuevo empieza en su día 1
	local back = H.rejoin(leo, saved)
	task.wait(3)
	local s2 = H.profiles[back].Story
	local p = s2.Active.Loco_N1_Cosme
	check(p and p.Step == 2 and p.Sub and p.Sub["1"] == true, "La misión sigue en el grupo de piezas con el tornillo cogido (1/3)")
	check(s2.Tracked == "Loco_N1_Cosme", "Y sigue siendo la que juegas")
	check(back.TeleportedTo == nil, "Un grupo de tareas repartido por la ciudad no te teletransporta al entrar (apareces donde lo dejaste)")
	check(s2.LoopDay == 12 and s2.Active.Nino_Jornada == nil, "El día de cole de hoy (día 12 de tu vida) ya está hecho: no vuelve a empezar en el servidor nuevo")
	Location.resolve = oldResolve
	H.defaultAttributes.LifeDay = nil
	-- Una partida vieja (LoopDay en días del servidor, sin LoopLife) no deja a nadie sin su día de cole
	local mia = H.newPlayer("Mia", "Nino", 3600)
	task.wait(0.5)
	H.profiles[mia].Story.LoopDay = 1
	local saved2 = viaDataStore(H.leave(mia))
	H.defaultAttributes.LifeDay = 1
	local mia2 = H.rejoin(mia, saved2)
	task.wait(0.5)
	check(H.profiles[mia2].Story.LoopDay == nil or H.profiles[mia2].Story.LoopDay ~= 1, "Partida de antes del arreglo: el LoopDay viejo (día del servidor) se olvida")
	H.defaultAttributes.LifeDay = nil
	local problems = H.saveProblems()
	check(#problems == 0, "Las partidas de la historia se pueden guardar (" .. #problems .. " problemas)")
	local _ = Service
end

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
process.exit(0)
