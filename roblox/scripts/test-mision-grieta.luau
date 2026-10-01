-- Prueba de la MISIÓN DE EJEMPLO del motor de escenas, de punta a punta (Lune, con StoryHarness):
-- Saga_02_Grieta «La grieta en el cielo».
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-mision-grieta.luau        (~1 min)
--
-- El jugador automático juega Loco_N1_Cosme y luego Saga_02_Grieta con la historia de verdad
-- (LifeStoryService). Comprueba:
--   * la misión pasa la validación (con su paso de escena Grieta_Caen);
--   * tras hablar con Cosme, la ESCENA deja tres cráteres HUMEANTES en la memoria del mundo (antes de
--     recoger nada: es una consecuencia de lo que se ve caer);
--   * al recoger cada cosa, su cráter se ENFRÍA (efecto World del paso) y suena la escena ligera;
--   * al acabar, Chispa se queda a vivir en el cráter del parque (Rewards.World);
--   * los decorados se publican (StageSets) y, al salir y volver a entrar, todo sigue ahí;
--   * la partida se puede guardar (SaveCheck).

local serde = require("@lune/serde")
local H = require("./lib/StoryHarness")
local ROOT, loadModule = H.ROOT, H.loadModule
local lighting, profiles = H.lighting, H.profiles
local check, newPlayer, received, fromClient = H.check, H.newPlayer, H.received, H.fromClient
local playQuest, said, passTime = H.playQuest, H.said, H.passTime

print("\n▶ Datos")
local problems = loadModule(ROOT .. "/shared/LifeStory/Validate").run()
local mine = {}
for _, problem in problems do
	if problem:find("Saga_02", 1, true) or problem:find("escena", 1, true) or problem:find("decorado", 1, true) then
		table.insert(mine, problem)
		print("    " .. problem)
	end
end
check(#mine == 0, "la misión, sus escenas y sus decorados pasan la validación")
local Quests = loadModule(ROOT .. "/shared/LifeStory/Quests")
local hasScene = false
for _, step in Quests.Saga_02_Grieta.Steps do
	if step.Type == "Cinematic" and step.Id == "Grieta_Caen" then
		hasScene = true
	end
end
check(hasScene, "Saga_02_Grieta lanza la escena Grieta_Caen")

H.boot()
local World = loadModule(ROOT .. "/server/Services/WorldMemoryService")
local history = {}
World.onChanged(function(player, key, value)
	table.insert(history, { Player = player.Name, Key = key, Value = value })
end)

-- Ir al sitio, esperar a que te la ofrezcan, aceptarla y jugarla entera (como test-lifestory)
local function playLoco(player, questId: string): boolean
	local quest = Quests[questId]
	local story = profiles[player].Story
	story.Declined[questId] = nil
	for _ = 1, 12 do
		if story.Active[questId] or story.Completed[questId] then
			break
		end
		player.At = quest.Offer.Place
		passTime(player, 5)
		if received(player, "Offer", quest.Title) then
			fromClient(player, "Offer", questId, true)
		end
	end
	return story.Active[questId] ~= nil and playQuest(player, questId, 200)
end

print("\n▶ Saga_02_Grieta con el motor de escenas")
local sol = newPlayer("Sol", "Nino")
local data = profiles[sol]
sol.Prefer = { "¡Te ayudo", "Será nuestro secreto", "¿Quién es Cósimo" }
lighting.ClockTime = 17
passTime(sol, 5)
check(playLoco(sol, "Loco_N1_Cosme"), "antes: el vecino del garaje")
sol.At = "Parque"
passTime(sol, 5)
check(playLoco(sol, "Saga_02_Grieta") and data.Items.MonedaPerilla == 1 and said(sol, "…Cósimo."), "La grieta en el cielo, jugada entera")

-- Qué pasó en la memoria del mundo, en orden
local order = {}
for _, h in history do
	if h.Player == "Sol" then
		table.insert(order, h.Key .. "=" .. tostring(h.Value))
	end
end
print("    memoria del mundo: " .. table.concat(order, ", "))
local function indexOf(entry)
	return table.find(order, entry) or math.huge
end
check(indexOf("Cielo.Crater.Parque=Humeante") < indexOf("Cielo.Crater.Parque=Frio"), "la escena deja el cráter del parque humeante; al recoger el calcetín se enfría")
check(indexOf("Cielo.Crater.Patio=Humeante") < indexOf("Cielo.Crater.Patio=Frio") and indexOf("Cielo.Crater.Camino=Humeante") < indexOf("Cielo.Crater.Camino=Frio"), "igual con el patio y el camino")
check(indexOf("Cielo.Crater.Camino=Humeante") < indexOf("Cielo.Crater.Parque=Frio"), "los tres caen (en la escena) antes de recoger nada")
local world = data.Story.World
check(world["Cielo.Crater.Parque"] == "Frio" and world["Cielo.Crater.Patio"] == "Frio" and world["Cielo.Crater.Camino"] == "Frio", "al acabar, los tres cráteres se quedan (fríos)")
check(world["Cielo.Chispa"] == "Parque", "Chispa se queda a vivir en el cráter del parque")
local sets = serde.decode("json", sol:GetAttribute("StageSets") or "{}")
check(sets.CraterParque and sets.CraterParque.S == "Frio" and sets.ChispaParque and sets.ChispaParque.S == "Vive", "sus decorados: cráter frío y Chispa viviendo en él")
check(type(sol:GetAttribute("WorldState")) == "string", "la memoria del mundo llega a su pantalla")

print("\n▶ Salir y volver a entrar")
local saveProblems = H.saveProblems()
check(#saveProblems == 0, "la partida se puede guardar (SaveCheck)")
local saved = H.leave(sol)
local back = H.rejoin(sol, saved)
World.publish(back)
local again = serde.decode("json", back:GetAttribute("StageSets") or "{}")
check(again.CraterParque and again.CraterParque.S == "Frio" and again.ChispaParque, "al volver, los cráteres y Chispa siguen ahí")

print("")
if H.failures > 0 then
	print(("❌ test-mision-grieta: %d comprobaciones fallan"):format(H.failures))
	require("@lune/process").exit(1)
end
print("✅ test-mision-grieta: todo correcto")
require("@lune/process").exit(0)
