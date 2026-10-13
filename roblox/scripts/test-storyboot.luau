-- Prueba: al entrar, la historia SIEMPRE llega al cliente (Lune, con StoryHarness).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-storyboot.luau
--
-- Por qué existe (v106 y v107, móvil): el dueño entraba y el «¿Qué hago ahora?» se quedaba para siempre
-- en «CARGANDO TU PARTIDA…», sin misiones. Ese texto sale mientras el cliente (UI/Hud) no ha recibido
-- ningún "State" de LifeStoryService. Cadenas que lo dejaban así:
--   1. publish fallaba con una partida concreta (un paso que ya no existe…): el error cortaba el envío
--      y cada "Sync" del cliente volvía a fallar igual.
--   2. onLoaded fallaba ANTES de crear el runtime del jugador: onRemote tiraba todos sus "Sync".
--   3. becomeReady: un error en el resumen, resumeAll o refresh cortaba antes de publish.
--   4. El cliente dejaba de pedir "Sync" a los 60 s (si la partida cargaba más tarde, nunca lo volvía a
--      pedir).
-- Ahora: publish manda un estado mínimo si el completo falla, onLoaded siempre deja runtime y vuelve a
-- intentar arrancar, "Sync" sin historia la carga, un vigilante (bootCheck) lo arregla solo, y el
-- cliente pide "Sync" hasta tenerlo.

local fs = require("@lune/fs")
local process = require("@lune/process")
local task = require("@lune/task")
local H = require("./lib/StoryHarness")

local Service = H.boot()
local check = H.check

local function blank(stage: string?): any
	return {
		Money = 325,
		Stats = { PlaySeconds = 5000 },
		Life = { Stage = stage or "Nino", AgeYears = 8, StageSeconds = 100 },
		Education = { Subjects = {}, Exams = {}, Degrees = {}, Attendance = 0 },
		Items = {},
		Story = {
			Version = 1,
			Chapters = {},
			Active = {},
			Completed = {},
			Declined = {},
			Choices = {},
			Flags = {},
			Discovered = {},
			NpcMemory = {},
			Events = {},
			PrologueDone = 1,
		},
	}
end

local function waitState(player, seconds: number): any
	local deadline = os.clock() + seconds
	repeat
		local state = H.lastState(player)
		if state then
			return state
		end
		task.wait(0.2)
	until os.clock() > deadline
	return nil
end

print("1. Una partida normal recibe su estado")
do
	local p = H.newPlayer("Normal", nil, nil, blank())
	check(waitState(p, 12) ~= nil, "llega el estado de la historia")
end

print("2. Una misión rota en la partida (sus pasos dan error): llega igual un estado")
do
	H.Quests.PruebaRota = {
		Kind = "Main",
		TitleKey = "PRUEBA.ROTA",
		Steps = setmetatable({}, {
			__index = function()
				error("paso roto (prueba)")
			end,
			__len = function()
				return 3
			end,
		}),
	}
	local profile = blank()
	profile.Story.Active.PruebaRota = { Step = 2, Count = 0, Started = 1, Kind = "Main" }
	profile.Story.Tracked = "PruebaRota"
	local before = Service.publishErrors
	local p = H.newPlayer("Rota", nil, nil, profile)
	local state = waitState(p, 14)
	check(state ~= nil, "llega un estado aunque la misión esté rota (no se queda en «CARGANDO TU PARTIDA…»)")
	check(Service.publishErrors > before, ("el error se apunta en el registro (%d)"):format(Service.publishErrors - before))
	check(state ~= nil and state.Degraded == true, "es el estado mínimo (Degraded)")
	H.Quests.PruebaRota = nil
end

print("3. onLoaded falla antes de crear el runtime: Sync / el vigilante lo arreglan")
do
	local profile = blank()
	profile.Life = nil -- (rompe la primera línea de onLoaded)
	local p = H.newPlayer("SinVida", nil, nil, profile)
	-- (newPlayer ya mandó un "Sync"; el estado llega por el arranque de después del fallo)
	local state = waitState(p, 14)
	check(state ~= nil, "llega un estado aunque onLoaded haya fallado al empezar")
end

print("4. La historia no recibió la partida (onLoaded nunca llegó): Sync la carga")
do
	local saved = H.loadedCallbacks
	local copy = table.clone(saved)
	table.clear(saved) -- (DataService no avisa a nadie)
	local p = H.newPlayer("SinAviso", nil, nil, blank())
	for _, cb in copy do
		table.insert(saved, cb)
	end
	check(H.lastState(p) == nil, "(sin aviso de DataService no hay estado todavía)")
	H.fromClient(p, "Sync")
	local state = waitState(p, 14)
	check(state ~= nil, "tras el siguiente Sync del cliente llega el estado")
end

print("5. Vigilante de arranque (sin ningún Sync)")
do
	local p = H.newPlayer("Vigilado", nil, nil, blank())
	waitState(p, 12)
	check(Service.bootCheck(p) == nil, "bootCheck: con la historia en marcha no hace nada")
	-- La historia pierde al jugador (su runtime) pero la partida sigue cargada
	H.players.PlayerRemoving:Fire(p)
	table.clear(p.Inbox)
	check(Service.bootCheck(p) == "Cargar", "bootCheck: partida sin historia → la carga")
	check(waitState(p, 14) ~= nil, "y llega el estado")
end

print("6. El cliente no deja de pedir su estado")
do
	local hud = fs.readFile("src/client/UI/Hud.luau")
	check(string.find(hud, "while not synced do", 1, true) ~= nil, "UI/Hud pide \"Sync\" hasta tenerlo (antes, 20 veces y paraba)")
end

print(("\n%s"):format(if H.failures == 0 then "✅ Todo correcto" else ("❌ %d fallos"):format(H.failures)))
process.exit(if H.failures == 0 then 0 else 1)
