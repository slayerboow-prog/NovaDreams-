-- Prueba de que siempre se ve tu misión y de la robustez de la historia (LifeStoryService):
--   1. Un niño con la principal oculta por horario (cole cerrado por la tarde o el fin de semana; o,
--      en horario de cole, una principal que no es del cole) la sigue viendo en la tarjeta, en pausa:
--      Tracked con Later = "School" y Closed = { Name, From, Weekdays }, o Later = "AfterSchool" (17:00),
--      sin línea guía. En horario de cole vuelve a ser la de siempre.
--   2. Pasos insertados en misiones ya publicadas (Cole09_Misterio paso 14, Saga_02_Grieta paso 2):
--      quien la empezó antes del cambio no retrocede; quien la empezó después no se mueve.
--   3. Al empezar una misión ya no queda una espera vieja (rt.Waiting).
--   4. Una escena de cámara en marcha (el montaje del cambio de etapa): la cabecera del capítulo
--      siguiente espera a que acabe (antes salían dos escenas a la vez).
--   5. Dos peticiones seguidas del cliente: la importante no se pierde (se atiende un poco después) y
--      el límite es por tipo de petición.
--   6. Si una parte del repaso lento falla (descubrir barrio…), el refresh sigue.
--
-- Uso (desde la carpeta roblox/): lune run scripts/test-mision-visible.luau   (~1 min)

local process = require("@lune/process")
local task = require("@lune/task")

local H = require("./lib/StoryHarness")
local check = H.check
local ROOT = H.ROOT

local Service = H.boot()
local Cine = H.loadModule(ROOT .. "/server/Services/CinematicService")
local LocationService = H.mocks[ROOT .. "/server/Services/LocationService"]
local REFRESH = H.Config.LifeStory.RefreshSeconds + 1

local function waitFor(condition: () -> boolean, seconds: number): boolean
	local since = os.clock()
	while os.clock() - since < seconds do
		if condition() then
			return true
		end
		task.wait(0.1)
	end
	return condition()
end

local COMPLETED = {
	Bebe_AprendeACaminar = 1, Bebe_ExploraLaCasa = 1, Bebe_HoraDeSalir = 1,
	Cole01_PrimerDia = 1, Cole02_Mochila = 1, Cole03_Grupo = 1,
}
local function child(name: string, active: { [string]: any }, tracked: string?, chapter: string?)
	local profile = {
		Money = 0,
		Stats = { PlaySeconds = 100 },
		Life = { Stage = "Nino", AgeYears = 7, StageSeconds = 3600 },
		Education = { Subjects = {}, Exams = {}, Degrees = {}, Attendance = 0 },
		Items = {},
		Story = {
			Version = 1, Chapter = chapter or "Nino_ElColegio", Chapters = { Bebe_PrimerosPasos = 1 },
			Active = active, Completed = table.clone(COMPLETED),
			Declined = {}, Choices = {}, Flags = {}, Discovered = {}, NpcMemory = {}, Events = {}, Tracked = tracked,
		},
	}
	return H.newPlayer(name, nil, nil, profile), profile
end

local function malotes(step: number): { [string]: any }
	return { Cole04_Malotes = { Step = step, Count = 0, Started = os.time(), Kind = "Main" } }
end

---------------------------------------------------------------------
print("\n▶ 1. La principal oculta por horario se sigue viendo, en pausa")
---------------------------------------------------------------------
H.setDay(6) -- sábado
H.lighting.ClockTime = 12
local sabado = child("Sabado", malotes(3), "Cole04_Malotes")
task.wait(REFRESH)
local state = H.lastState(sabado)
local tracked = state and state.Tracked
check(tracked and tracked.QuestId == "Cole04_Malotes", "Sábado a mediodía: la tarjeta enseña «Los malotes» (antes, ninguna misión)")
check(tracked and tracked.Later == "School" and tracked.Closed and tracked.Closed.Name == "El colegio" and tracked.Closed.From == H.Config.SchoolDay.Opens,
	"…en pausa hasta que abra el colegio (Later = School, Closed = El colegio, abre a las 8:30)")
check(tracked and tracked.Closed and type(tracked.Closed.Weekdays) == "table" and table.find(tracked.Closed.Weekdays, 6) == nil and table.find(tracked.Closed.Weekdays, 1) ~= nil,
	"…con sus días (de lunes a viernes: el HUD puede decir «abre el lunes»)")
check(sabado:GetAttribute("StoryTarget") == nil, "…y sin línea guía")
check(#state.Others == 0, "No sale repetida en la lista de las demás")
check(tracked and tracked.StepType ~= nil, "Dice de qué tipo es el paso (para «Mira la escena»… si no tiene texto)")

H.setDay(1) -- lunes
H.lighting.ClockTime = 19
local lunes = child("Lunes19", malotes(3), "Cole04_Malotes")
task.wait(REFRESH)
state = H.lastState(lunes)
check(state and state.Tracked and state.Tracked.QuestId == "Cole04_Malotes" and state.Tracked.Later == "School", "Lunes a las 19:00: en pausa hasta mañana (antes, ninguna misión)")
H.lighting.ClockTime = 10
check(waitFor(function()
	local s = H.lastState(lunes)
	return s and s.Tracked and s.Tracked.QuestId == "Cole04_Malotes" and s.Tracked.Later == nil and s.Tracked.Closed == nil
end, REFRESH + 2), "Lunes a las 10:00: la misión vuelve a jugarse (sin «en pausa»)")

-- En horario de cole, una que no es del cole (la de Mateo) espera a las 17:00
-- (como principal: así no empieza otra principal del cole que la tape)
local tarde = child("Mateo10", { Eco_MateoDibujo = { Step = 1, Count = 0, Started = os.time(), Kind = "Main" } }, "Eco_MateoDibujo")
task.wait(REFRESH)
state = H.lastState(tarde)
check(state and state.Tracked and state.Tracked.QuestId == "Eco_MateoDibujo" and state.Tracked.Later == "AfterSchool" and state.Tracked.From == H.Config.SchoolDay.End,
	"Lunes a las 10:00 sin misión del cole: «Sigue al salir del cole (17:00)»")
check(tarde:GetAttribute("StoryFocus") == nil, "La que está en pausa no se juega (StoryFocus vacío)")

---------------------------------------------------------------------
print("\n▶ 2. Pasos insertados en misiones ya publicadas")
---------------------------------------------------------------------
local COLE09_SINCE = 1791291138 -- 2026-10-06 12:52:18 UTC (commit que metió Cole09_LaFoto)
local SAGA02_SINCE = 1790879853 -- 2026-10-01 18:37:33 UTC (commit que metió Grieta_Caen)
local old = { Step = 14, Started = COLE09_SINCE - 3600 }
Service.migrateSteps("Cole09_Misterio", old)
check(old.Step == 15 and old.V == 2, "Cole09 empezada antes: en «La foto» (antes 14) sigue en «La foto» (ahora 15)")
local before = { Step = 13, Started = COLE09_SINCE - 3600 }
Service.migrateSteps("Cole09_Misterio", before)
check(before.Step == 13, "Cole09 empezada antes, aún en el paso 13: no se mueve (verá la escena nueva)")
local after = { Step = 14, Started = COLE09_SINCE + 60 }
Service.migrateSteps("Cole09_Misterio", after)
check(after.Step == 14 and after.V == 2, "Cole09 empezada después del cambio: no se mueve")
local saga = { Step = 2, Started = SAGA02_SINCE - 60 }
Service.migrateSteps("Saga_02_Grieta", saga)
check(saga.Step == 3, "Saga_02 empezada antes: del paso 2 (el grupo) al 3 (el mismo grupo)")
local sagaFirst = { Step = 1, Started = SAGA02_SINCE - 60 }
Service.migrateSteps("Saga_02_Grieta", sagaFirst)
check(sagaFirst.Step == 1, "Saga_02 en el paso 1: no se mueve")
local sagaNew = { Step = 2, Started = SAGA02_SINCE + 60 }
Service.migrateSteps("Saga_02_Grieta", sagaNew)
check(sagaNew.Step == 2, "Saga_02 empezada después: no se mueve")
local twice = { Step = 14, Started = COLE09_SINCE - 3600 }
Service.migrateSteps("Cole09_Misterio", twice)
Service.migrateSteps("Cole09_Misterio", twice)
check(twice.Step == 15, "Migrar dos veces no corre el paso dos veces")
check(H.Quests.Cole09_Misterio.Steps[14].Type == "Cinematic" and H.Quests.Saga_02_Grieta.Steps[2].Type == "Cinematic", "(los pasos insertados son esas escenas)")

---------------------------------------------------------------------
print("\n▶ 3. Al empezar una misión no queda una espera vieja")
---------------------------------------------------------------------
local debug = Service.debugState(lunes)
check(debug and debug.Waiting == nil, "Con la misión en marcha, Waiting está vacío")

---------------------------------------------------------------------
print("\n▶ 4. La cabecera del capítulo espera a que acabe el montaje")
---------------------------------------------------------------------
H.lighting.ClockTime = 10
local etapa, etapaData = child("Etapa", malotes(3), "Cole04_Malotes")
task.wait(1)
Cine.beginScene(etapa, "Montaje_Bebe_Nino", 40)
-- Acaba la última misión del capítulo anterior y no hay capítulo: toca entrar en el del cole
etapaData.Story.Active = {}
etapaData.Story.Tracked = nil
etapaData.Story.Chapter = nil
etapaData.Story.Completed.Cole04_Malotes = nil
table.clear(etapa.Inbox)
task.wait(REFRESH)
check(etapaData.Story.Chapter == nil and not H.cinematic(etapa, "Cole01_Amanecer"), "Con el montaje en pantalla no entra el capítulo (ni su escena)")
Cine.endScene(etapa, "Montaje_Bebe_Nino")
check(waitFor(function()
	return etapaData.Story.Chapter ~= nil
end, 3), "Al acabar el montaje, entra el capítulo (" .. tostring(etapaData.Story.Chapter) .. ")")

---------------------------------------------------------------------
print("\n▶ 5. Peticiones seguidas: la importante no se pierde")
---------------------------------------------------------------------
H.lighting.ClockTime = 18
local rapido, rapidoData = child("Rapido", {
	Cole04_Malotes = { Step = 3, Count = 0, Started = os.time(), Kind = "Main" },
	Eco_MateoDibujo = { Step = 1, Count = 0, Started = os.time(), Kind = "Side" },
}, "Cole04_Malotes")
task.wait(1)
H.remote.OnServerEvent:Fire(rapido, "Track", "Eco_MateoDibujo")
check(rapidoData.Story.Tracked == "Eco_MateoDibujo", "Seguir otra misión: al momento")
H.remote.OnServerEvent:Fire(rapido, "Journal")
H.remote.OnServerEvent:Fire(rapido, "Track", "Cole04_Malotes")
check(rapidoData.Story.Tracked == "Eco_MateoDibujo", "…otra justo después (0 s): no se atiende todavía")
check(waitFor(function()
	return rapidoData.Story.Tracked == "Cole04_Malotes"
end, 1), "…pero no se pierde: se atiende al acabar la espera")
local journals = 0
for _, message in rapido.Inbox do
	journals += if message.Kind == "Journal" then 1 else 0
end
check(journals == 1, "El límite es por tipo: «Mi historia» se abre aunque acabaras de seguir otra misión")

---------------------------------------------------------------------
print("\n▶ 6. Un fallo en el repaso lento no para el refresh")
---------------------------------------------------------------------
local realZoneAt = LocationService.zoneAt
LocationService.zoneAt = function()
	error("barrio roto (prueba)")
end
H.setDay(1)
H.lighting.ClockTime = 19
local roto = child("Roto", malotes(3), "Cole04_Malotes")
task.wait(REFRESH)
H.lighting.ClockTime = 10
check(waitFor(function()
	local s = H.lastState(roto)
	return s and s.Tracked and s.Tracked.QuestId == "Cole04_Malotes" and s.Tracked.Later == nil
end, REFRESH + 2), "Con discoverZone fallando, la tarjeta se sigue poniendo al día")
LocationService.zoneAt = realZoneAt

print(if H.failures == 0 then "\n✅ Todo correcto" else ("\n❌ %d fallos"):format(H.failures))
process.exit(if H.failures == 0 then 0 else 1)
