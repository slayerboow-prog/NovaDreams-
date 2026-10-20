-- Prueba de los primeros pasos FUERA de Roblox, con Lune (la parte que no es interfaz).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-onboarding.luau
--
-- Comprueba:
--   * shared/Onboarding: quién hace el tutorial (nuevo sí, quien ya jugaba no), la lista de pasos,
--     las ideas de "¿Qué hago ahora?" (edad, hora y tiendas abiertas) y las pistas si te atascas
--     (a los 90 s, nunca en conversaciones, como mucho dos veces, y si te alejas mucho rato).
--   * DataService + OnboardingService de verdad (con un DataStore de mentira): un perfil nuevo tiene
--     tutorial y uno que ya jugaba no; los pasos, «Saltar», «Ver tutorial otra vez» y los consejos se
--     guardan y al volver a entrar no se repite nada; lo que llega del cliente se comprueba; y
--     «Empezar una vida nueva» no vuelve a enseñar el tutorial.
-- La interfaz (la tarjeta, el ❓, «Llévame», el prólogo, que nada se pisa…) la prueba scripts/test-hud.luau.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3 = roblox.Vector3

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
-- Un Roblox de mentira muy pequeño (lo justo para DataService y OnboardingService)
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
				fn(...)
			end
		end,
	}
end

local function instance(className: string, name: string?): any
	local self: any = { ClassName = className, Name = name or className, Parent = nil, __children = {}, __attributes = {} }
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
	function self:GetAttribute(key)
		return self.__attributes[key]
	end
	function self:SetAttribute(key, value)
		self.__attributes[key] = value
	end
	function self:IsA(other)
		return other == className
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

local replicated = instance("ReplicatedStorage")
local remotes = instance("Folder", "Remotes")
remotes.Parent = replicated
local onboardingRemote = instance("RemoteEvent", "Onboarding")
onboardingRemote.OnServerEvent = signal()
onboardingRemote.Parent = remotes
local newLifeRemote = instance("RemoteEvent", "NewLife")
newLifeRemote.OnServerEvent = signal()
newLifeRemote.Parent = remotes

-- DataStore de mentira: lo guardado de cada jugador, como en Roblox (UpdateAsync)
local stored: { [string]: any } = {}
local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value do
		out[k] = deepCopy(v)
	end
	return out
end
local fakeStore = {
	UpdateAsync = function(_, key, fn)
		local result = fn(deepCopy(stored[key]))
		if result ~= nil then
			stored[key] = deepCopy(result)
		end
	end,
}

local playerAdded, playerRemoving = signal(), signal()
local services = {
	ReplicatedStorage = replicated,
	DataStoreService = { GetDataStore = function()
		return fakeStore
	end },
	Players = { PlayerAdded = playerAdded, PlayerRemoving = playerRemoving, GetPlayers = function()
		return {}
	end },
	RunService = { IsStudio = function()
		return false
	end },
	Lighting = { ClockTime = 12 },
}
local fakeGame = {
	JobId = "servidor-de-prueba",
	GetService = function(_, name)
		return services[name] or error("Servicio sin simular: " .. name)
	end,
	BindToClose = function() end,
}
local fakeTask = {
	spawn = function(fn, ...)
		local thread = coroutine.create(fn)
		local ok, err = coroutine.resume(thread, ...)
		if not ok then
			error(err)
		end
		return thread
	end,
	wait = function()
		coroutine.yield()
	end,
	delay = function() end,
	defer = function(fn, ...)
		fn(...)
	end,
}

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
replicated.Shared = node("src/shared")

local cache: { [string]: any } = {}
local function load(path: string): any
	if cache[path] ~= nil then
		return cache[path]
	end
	local env = setmetatable({
		script = node(path),
		require = function(target)
			return load(rawget(target, "__path"))
		end,
		game = fakeGame,
		task = fakeTask,
		Vector3 = Vector3,
		Vector2 = roblox.Vector2,
		Color3 = roblox.Color3,
		UDim2 = roblox.UDim2,
		CFrame = roblox.CFrame,
		Enum = roblox.Enum,
		Instance = { new = function(className)
			return instance(className)
		end },
		warn = function() end,
		typeof = function(value)
			if type(value) == "table" and value.ClassName then
				return "Instance"
			end
			return typeof(value)
		end,
	}, { __index = _G })
	local result = luau.load(fs.readFile(path .. ".luau"), { debugName = path, environment = env })()
	cache[path] = result
	return result
end

local Onboarding = load("src/shared/Onboarding")

---------------------------------------------------------------------
print("\n▶ ¿A quién le toca el tutorial? (shared/Onboarding)")
check(Onboarding.decide("", 0) == "Pendiente", "Perfil nuevo (sin tiempo jugado): «Pendiente»")
check(Onboarding.decide("", 3600) == "Veterano", "Perfil que ya jugaba antes: «Veterano» (sin tutorial)")
check(Onboarding.decide(nil, 0) == "Pendiente", "Sin el campo todavía: igual que nuevo")
check(Onboarding.decide("Saltado", 0) == "Saltado" and Onboarding.decide("Hecho", 99999) == "Hecho", "Lo ya decidido no cambia (nunca se repite)")
local ids = {}
for _, step in Onboarding.Steps do
	table.insert(ids, step.Id)
end
check(table.concat(ids, ",") == "Mover,Correr,Interactuar,Mapa,Mochila,Ayuda,Mision", "Pasos en orden: " .. table.concat(ids, ", "))
local texts = true
for _, step in Onboarding.Steps do
	texts = texts and #step.Title > 0 and #step.Touch > 10 and #step.Keys > 10 and step.Target.Touch ~= nil and step.Target.Keys ~= nil
end
check(texts, "Cada paso tiene su título, el texto para el móvil y para el teclado, y qué se señala")
check(Onboarding.encode({ Mover = true, Correr = true }) == "Correr,Mover" and Onboarding.decode("Correr,Mover").Mover == true, "Los pasos hechos van en un atributo («Correr,Mover»)")
check(Onboarding.nextStep({ Mover = true, Correr = true, Interactuar = true, Mapa = true }).Id == "Mochila", "La tarjeta enseña el primero que falta (tras el prólogo: la mochila)")
local tipIds = {}
for id in Onboarding.Tips do
	table.insert(tipIds, id)
end
table.sort(tipIds)
check(table.concat(tipIds, ",") == "Busqueda,Gimnasio,Necesidades,Tienda,Transporte,Vehiculo", "Consejos de la primera vez: " .. table.concat(tipIds, ", "))

---------------------------------------------------------------------
print("\n▶ ¿Qué hago ahora? (sin misión)")
local function ideas(ctx): { string }
	local out = {}
	for _, s in Onboarding.suggest(ctx) do
		table.insert(out, s.Id)
	end
	return out
end
local function has(list: { string }, id: string): boolean
	return table.find(list, id) ~= nil
end
local kidMorning = ideas({ Stage = "Nino", Clock = 10, Weekday = 2 })
check(#kidMorning >= 2 and #kidMorning <= 3 and kidMorning[1] == "Clase", "Niño, martes a las 10:00: primero, ir al colegio (" .. table.concat(kidMorning, ", ") .. ")")
local kidWeekend = ideas({ Stage = "Nino", Clock = 10, Weekday = 6 })
check(not has(kidWeekend, "Clase") and has(kidWeekend, "Parque"), "El sábado no hay cole: el parque (" .. table.concat(kidWeekend, ", ") .. ")")
local kidNight = ideas({ Stage = "Nino", Clock = 23, Weekday = 2 })
check(kidNight[1] == "Dormir" and #kidNight >= 2 and not has(kidNight, "Clase") and not has(kidNight, "Parque") and not has(kidNight, "Recreativos"), "De noche, a un niño: a dormir, sin mandarle de paseo (" .. table.concat(kidNight, ", ") .. ")")
local adultHungry = Onboarding.suggest({ Stage = "Adulto", Clock = 12, Hunger = 20 })
check(adultHungry[1].Id == "Comer" and adultHungry[1].Place == "Supermercado", "Adulto con hambre a mediodía: comprar en el supermercado (abierto)")
local lateHungry = Onboarding.suggest({ Stage = "Adulto", Clock = 23.5, Hunger = 20 })
local lateIds = {}
for _, s in lateHungry do
	table.insert(lateIds, s.Id)
	check(s.Place ~= "Supermercado" and s.Place ~= "GimnasioValmar", "A las 23:30 nada de sitios cerrados: «" .. s.Text .. "»")
end
check(has(lateIds, "Comer") and has(lateIds, "Dormir"), "…sino la nevera de casa y dormir")
check(#ideas({ Stage = "Adulto", Clock = 11 }) == 3 and has(ideas({ Stage = "Adulto", Clock = 11 }), "Trabajo"), "Adulto sin trabajo por la mañana: 3 ideas, una para ganar dinero")
check(not has(ideas({ Stage = "Adulto", Clock = 11, Job = "Cajero" }), "Trabajo"), "Si ya trabaja, no se le dice que busque trabajo")
check(ideas({ Stage = "Adulto", Clock = 11, Wanted = 2 })[1] == "Esconderse", "Con estrellas de búsqueda, lo primero es esconderse")
check(ideas({ Stage = "Bebe", Clock = 11 })[1] == "Familia", "De bebé: explorar la casa con la familia")
local marks = { { Kind = "Parque", Position = Vector3.new(500, 0, 0) }, { Kind = "Parque", Position = Vector3.new(60, 0, 0) }, { Kind = "Plaza", Position = Vector3.new(10, 0, 0) } }
check(Onboarding.nearest(marks, "Parque", Vector3.new(0, 0, 0)) == Vector3.new(60, 0, 0), "«Llévame» va al parque más cercano")
check(Onboarding.direction(Vector3.new(0, 0, 0), Vector3.new(0, 0, -100)) == "hacia el norte" and Onboarding.direction(Vector3.new(0, 0, 0), Vector3.new(100, 0, 100)) == "hacia el sureste", "Hacia dónde queda («hacia el norte», «hacia el sureste»)")

---------------------------------------------------------------------
print("\n▶ Pistas si te atascas")
local s = Onboarding.newStuck()
local got = {}
for _ = 1, 200 do
	local kind = Onboarding.stuckStep(s, 1, "Ve al colegio", 300, true)
	if kind then
		table.insert(got, kind)
	end
end
check(#got == 0, "En conversaciones o cinemáticas el tiempo no cuenta (200 s: ninguna pista)")
local times = {}
for t = 1, 1000 do
	if Onboarding.stuckStep(s, 1, "Ve al colegio", 300, false) then
		table.insert(times, t)
	end
end
check(times[1] == 90, "Pista a los 90 s jugando sin avanzar (" .. tostring(times[1]) .. " s)")
check(#times == 2, "La misma pista, como mucho dos veces (" .. #times .. " en 1000 s)")
s = Onboarding.newStuck()
local walking = nil
for t = 1, 200 do
	-- vas hacia el objetivo (te acercas 2 studs por segundo): no te atascas
	if Onboarding.stuckStep(s, 1, "Ve al parque", 1000 - t * 2, false) and not walking then
		walking = t
	end
end
check(walking == nil, "Si vas acercándote al objetivo, no hay pista aunque tardes")
s = Onboarding.newStuck()
local away = nil
Onboarding.stuckStep(s, 1, "Ve al parque", 100, false)
for t = 1, 60 do
	if Onboarding.stuckStep(s, 1, "Ve al parque", 200, false) == "Away" and not away then
		away = t
	end
end
check(away == 45, "Alejándote del objetivo 45 s: pista «te estás alejando» (" .. tostring(away) .. " s)")
s = Onboarding.newStuck()
for _ = 1, 80 do
	Onboarding.stuckStep(s, 1, "Paso 1", 300, false)
end
check(Onboarding.stuckStep(s, 20, "Paso 2", 300, false) == nil and s.StepTime == 20, "Al avanzar de paso, la cuenta empieza de cero")

---------------------------------------------------------------------
print("\n▶ Se guarda (DataService + OnboardingService)")
local DataService = load("src/server/Services/DataService")
local Service = load("src/server/Services/OnboardingService")
DataService.init()
Service.init()

local function newPlayer(id: number): any
	local p = instance("Player", "Jugador" .. id)
	p.UserId = id
	p.Parent = instance("Players")
	p.Kick = function() end
	return p
end
local function join(p: any)
	playerAdded:Fire(p)
end
local function leave(p: any)
	playerRemoving:Fire(p)
end
local function send(p: any, ...)
	onboardingRemote.OnServerEvent:Fire(p, ...)
end

-- Nuevo
local ana = newPlayer(1)
join(ana)
check(ana:GetAttribute("Tutorial") == "Pendiente" and ana:GetAttribute("TutorialSteps") == "", "Perfil nuevo: le toca el tutorial («Pendiente»)")
-- Uno que ya jugaba antes de existir el tutorial (su perfil guardado no tiene el campo)
stored.Player_2 = { Money = 900, Stats = { TasksDone = 3, MoneyEarned = 800, PlaySeconds = 7200 }, Life = { AgeYears = 30, Stage = "Adulto" } }
local luis = newPlayer(2)
join(luis)
check(luis:GetAttribute("Tutorial") == "Veterano", "Perfil que ya jugaba: sin tutorial («Veterano»)")
send(luis, "Step", "Mover")
check(luis:GetAttribute("TutorialSteps") == "", "A un veterano no se le apuntan pasos")

send(ana, "Step", "Mover")
send(ana, "Step", "Correr")
send(ana, "Step", "Volar") -- (no existe)
send(ana, "Step", { "raro" })
send(ana, "Nada")
check(ana:GetAttribute("TutorialSteps") == "Correr,Mover", "Los pasos hechos se guardan; lo que no existe se ignora (" .. tostring(ana:GetAttribute("TutorialSteps")) .. ")")
send(ana, "Tip", "Vehiculo")
send(ana, "Tip", "Inventado")
check(ana:GetAttribute("TipsSeen") == "Vehiculo", "Los consejos vistos se guardan (y los inventados no)")
leave(ana)
check(stored.Player_1 and stored.Player_1.Onboarding.Steps.Mover == true and stored.Player_1.Onboarding.Tips.Vehiculo == true, "Al salir se guarda en el perfil (Onboarding.Steps y Onboarding.Tips)")
ana = newPlayer(1)
join(ana)
check(ana:GetAttribute("Tutorial") == "Pendiente" and ana:GetAttribute("TutorialSteps") == "Correr,Mover" and ana:GetAttribute("TipsSeen") == "Vehiculo", "Al volver sigue donde lo dejó (sin repetir pasos ni consejos)")

-- Saltar
send(ana, "Skip")
check(ana:GetAttribute("Tutorial") == "Saltado", "«Saltar» se guarda")
send(ana, "Step", "Mapa")
check(ana:GetAttribute("TutorialSteps") == "Correr,Mover", "Después de saltarlo ya no se apuntan pasos")
leave(ana)
ana = newPlayer(1)
join(ana)
check(ana:GetAttribute("Tutorial") == "Saltado", "Al volver a entrar no vuelve a salir")

-- Ver otra vez y terminarlo
send(ana, "Restart")
check(ana:GetAttribute("Tutorial") == "Pendiente" and ana:GetAttribute("TutorialSteps") == "", "«Ver tutorial otra vez»: de nuevo, desde el primer paso")
for _, step in Onboarding.Steps do
	send(ana, "Step", step.Id)
end
check(ana:GetAttribute("Tutorial") == "Hecho", "Con todos los pasos hechos: «Hecho»")
leave(ana)
ana = newPlayer(1)
join(ana)
check(ana:GetAttribute("Tutorial") == "Hecho", "Y así se queda al volver")

-- Vida nueva: se empieza de bebé, pero el tutorial ya visto no se repite
DataService.newLife(ana)
ana = newPlayer(1)
join(ana)
check(stored.Player_1.Life.Stage == "Bebe" and ana:GetAttribute("Tutorial") == "Hecho" and ana:GetAttribute("TipsSeen") == "Vehiculo", "«Empezar una vida nueva» no vuelve a enseñar el tutorial ni los consejos")

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
