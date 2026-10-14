-- Prueba de que un minijuego de una misión (los pases, los penaltis…) NO se queda en marcha cuando
-- empiezas otra cosa, y que se puede repetir (LifeStoryService + MiniGameService).
--
-- Lo que pidió el dueño: «le pasé la pelota a Mateo y empecé otra misión y la de Mateo sigue» (el
-- marcador de los pases seguía arriba, encima de la narración de la escena nueva).
--
--   1. Con el minijuego en marcha te pones a seguir OTRA misión: el minijuego se corta (al cliente le
--      llega «Cancel»), no cuenta ni como ganado ni como perdido (el paso es el mismo) y no vuelve a
--      empezar solo mientras sigues la otra.
--   2. Vuelves a seguir la primera: el minijuego vuelve a empezar.
--   3. En mitad del minijuego empieza una conversación o una escena (InDialogue): se corta; al acabar
--      la conversación, vuelve a empezar.
--   4. Te vas del campo (MiniGameService: el deporte lo da por abandonado): se corta sin contar y
--      espera un poco antes de volver a proponerse (si no, te llevaría otra vez al campo nada más irte);
--      tocar la misión en el panel lo deja empezar ya.
--   5. Al final se juega entero y la misión sigue (el paso se cumple).
--
-- Uso (desde la carpeta roblox/): lune run scripts/test-minijuego-corte.luau   (~1 min)

local process = require("@lune/process")
local task = require("@lune/task")

local H = require("./lib/StoryHarness")
local check = H.check
local ROOT = H.ROOT

local Service = H.boot()
local MGS = H.loadModule(ROOT .. "/server/Services/MiniGameService")
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

-- El paso de los penaltis de «El grupo» (Cole03_Grupo): con Nico invitado
local QUEST = "Cole03_Grupo"
local OTHER = "Cole04_Malotes"
local stepIndex = nil
for i, step in H.Quests[QUEST].Steps do
	if step.Type == "MiniGame" and step.Game == "Penaltis" then
		stepIndex = i
		break
	end
end
assert(stepIndex, "Cole03_Grupo ya no tiene el paso de los penaltis")

H.setDay(1) -- lunes
H.lighting.ClockTime = 10
local profile = {
	Money = 0,
	Stats = { PlaySeconds = 100 },
	Life = { Stage = "Nino", AgeYears = 7, StageSeconds = 3600 },
	Education = { Subjects = {}, Exams = {}, Degrees = {}, Attendance = 0 },
	Items = {},
	Story = {
		Version = 1,
		Chapter = "Nino_ElColegio",
		Chapters = { Bebe_PrimerosPasos = 1 },
		Active = {
			[QUEST] = { Step = stepIndex, Count = 0, Started = os.time(), Kind = "Main" },
			[OTHER] = { Step = 3, Count = 0, Started = os.time(), Kind = "Main" },
		},
		Completed = { Bebe_AprendeACaminar = 1, Bebe_ExploraLaCasa = 1, Bebe_HoraDeSalir = 1, Cole01_PrimerDia = 1, Cole02_Mochila = 1 },
		Declined = {},
		Choices = { Invitacion = { V = "Nico" } },
		Flags = {},
		Discovered = {},
		NpcMemory = {},
		Events = {},
		Tracked = QUEST,
	},
}
local leo = H.newPlayer("Leo", nil, nil, profile)
leo.HoldGames = true -- (el jugador de mentira no contesta: el juego sigue en marcha hasta que lo diga la prueba)

local function starts(): number
	local n = 0
	for _, message in leo.GameLog or {} do
		if message.Kind == "Start" and message.Payload.Spec and message.Payload.Spec.Game == "Penaltis" then
			n += 1
		end
	end
	return n
end
local function cancels(): number
	local n = 0
	for _, message in leo.GameLog or {} do
		if message.Kind == "Cancel" then
			n += 1
		end
	end
	return n
end
local function lastToken(): number?
	local token = nil
	for _, message in leo.GameLog or {} do
		if message.Kind == "Start" then
			token = message.Payload.Token
		end
	end
	return token
end
local function questStep(): number?
	local prog = profile.Story.Active[QUEST]
	return prog and prog.Step
end
local function busy(): boolean
	local dbg = Service.debugState(leo)
	return dbg ~= nil and dbg.Busy == true
end

---------------------------------------------------------------------
print("\n▶ 0. Empieza el minijuego del paso")
---------------------------------------------------------------------
check(waitFor(function()
	return MGS.isRunning(leo) and starts() >= 1
end, REFRESH * 3), ("Los penaltis de «%s» (paso %d) empiezan solos"):format(QUEST, stepIndex))

---------------------------------------------------------------------
print("\n▶ 1. Te pones a seguir otra misión: el minijuego se corta")
---------------------------------------------------------------------
local startsBefore, cancelsBefore = starts(), cancels()
H.fromClient(leo, "Track", OTHER)
check(waitFor(function()
	return not MGS.isRunning(leo)
end, 3), "Al seguir otra misión, el minijuego de la de antes deja de estar en marcha (servidor)")
check(cancels() > cancelsBefore, "…y al cliente le llega «Cancel» (se cierra su panel)")
check(questStep() == stepIndex and not profile.Story.Completed[QUEST], "…sin contar: la misión sigue en el mismo paso (se puede repetir)")
check(not busy(), "…y la historia no se queda ocupada")
task.wait(REFRESH + 2)
check(starts() == startsBefore and not MGS.isRunning(leo), "Mientras sigues la otra, el minijuego no vuelve a empezar solo encima")

---------------------------------------------------------------------
print("\n▶ 2. Vuelves a seguirla: el minijuego vuelve a empezar")
---------------------------------------------------------------------
H.fromClient(leo, "Track", QUEST)
check(waitFor(function()
	return MGS.isRunning(leo) and starts() > startsBefore
end, REFRESH * 3), "Al volver a seguirla, los penaltis empiezan otra vez")

---------------------------------------------------------------------
print("\n▶ 3. Empieza una conversación o una escena en mitad del juego")
---------------------------------------------------------------------
task.wait(1.2) -- (el vigilante ya lo ha visto sin conversación)
startsBefore, cancelsBefore = starts(), cancels()
-- (una conversación de verdad: mientras dura, InDialogue sigue puesto; aquí se vuelve a poner por si
-- otra parte del servidor de mentira, al acabar una conversación suya, lo quita)
local talking = true
task.spawn(function()
	while talking do
		leo:SetAttribute("InDialogue", true)
		task.wait(0.05)
	end
end)
check(waitFor(function()
	return not MGS.isRunning(leo)
end, 3), "Una conversación encima: el minijuego se corta (no sigue debajo de la narración)")
check(cancels() > cancelsBefore and questStep() == stepIndex, "…se cierra en el cliente y el paso sigue siendo el mismo")
task.wait(REFRESH)
check(not MGS.isRunning(leo) and starts() == startsBefore, "Mientras dura la conversación, no vuelve a empezar")
talking = false
task.wait(0.1)
leo:SetAttribute("InDialogue", nil)
check(waitFor(function()
	return MGS.isRunning(leo) and starts() > startsBefore
end, REFRESH * 3), "Al acabar la conversación, el minijuego vuelve a empezar")

---------------------------------------------------------------------
print("\n▶ 4. Te vas del campo: se corta sin contar y espera un poco")
---------------------------------------------------------------------
local step = H.Quests[QUEST].Steps[stepIndex]
MGS.cancel(leo, "Probando") -- (lo corta como lo haría el deporte…)
Service.gameCancelled(leo, QUEST, stepIndex, step, "Away") -- (…con el motivo de irse del campo)
check(Service.gameHeld(leo, QUEST, stepIndex), "Irse del campo: el paso espera (no te devuelve al campo nada más irte)")
startsBefore = starts()
task.wait(REFRESH + 1)
check(starts() == startsBefore and questStep() == stepIndex, "…y mientras espera no empieza ni cuenta como perdido")
H.fromClient(leo, "Track", QUEST)
check(waitFor(function()
	return MGS.isRunning(leo) and starts() > startsBefore
end, REFRESH * 3), "Tocar la misión en el panel: vuelve a empezar ya")

---------------------------------------------------------------------
print("\n▶ 5. Esta vez se juega entero: el paso se cumple")
---------------------------------------------------------------------
task.wait(2)
H.miniGameRemote.OnServerEvent:Fire(leo, "Result", lastToken(), { Hits = 3 })
check(waitFor(function()
	local now = questStep()
	return now == nil or now > stepIndex or profile.Story.Completed[QUEST] ~= nil
end, 5), "Al jugarlo entero, la misión pasa al paso siguiente")

print()
if H.failures > 0 then
	print(("❌ test-minijuego-corte: %d fallos"):format(H.failures))
	process.exit(1)
end
print("✅ test-minijuego-corte: todo correcto")
process.exit(0)
