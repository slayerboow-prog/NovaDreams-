-- Prueba automática de la historia de vida (LifeStoryService) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-lifestory.luau
--
-- Carga los módulos reales de src/ con un "Roblox de mentira" (jugadores, reloj, remotos) y
-- simula vidas completas: el capítulo puente, una secundaria, una decisión con ramas y el
-- paso de bebé a niño. Sustituye por dobles solo lo que necesita el mapa de verdad
-- (DataService, LocationService), así que prueba la lógica de la historia tal cual.

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

-- El "Roblox de mentira" y el jugador automático están en lib/StoryHarness (también los usa test-playthrough)
local H = require("./lib/StoryHarness")
local ROOT, TestRandom, loadModule = H.ROOT, H.TestRandom, H.loadModule
local lighting, profiles, scenes, classCalls = H.lighting, H.profiles, H.scenes, H.classCalls
local Config = H.Config
local check, newPlayer, received, cinematic, momentSting, lastState, fromClient = H.check, H.newPlayer, H.received, H.cinematic, H.momentSting, H.lastState, H.fromClient

-- Las escenas escritas a mano (Happenings: la parada, la graduación…) también «se dicen»: al acabar,
-- sus frases (las que tocan a ese jugador, con sus variantes) van a lo que ha oído (said)
do
	local Happening = loadModule(ROOT .. "/server/Services/HappeningService")
	local Sequencer = loadModule(ROOT .. "/shared/LifeStory/Sequencer")
	local Index = loadModule(ROOT .. "/shared/LifeStory/HappeningIndex")
	Happening.onFinished(function(player, id)
		local def = Index.get(id)
		if def and type(player.Said) == "table" then
			local ok, tl = pcall(function()
				return Sequencer.compile(id, def, Sequencer.resolve(def, Happening.checker(player)))
			end)
			for _, line in (ok and tl.Def.Tracks.Dialogue) or {} do
				table.insert(player.Said, line.T)
			end
		end
	end)
end

-- Las escenas del motor (Happenings: los montajes de cambio de etapa, el final de la vida) no llegan
-- como "Cinematic" a la pantalla: se apuntan al acabar (HappeningService.onFinished)
local scenesPlayed: { [any]: { [string]: boolean } } = {}
loadModule(ROOT .. "/server/Services/HappeningService").onFinished(function(p, id)
	scenesPlayed[p] = scenesPlayed[p] or {}
	scenesPlayed[p][id] = true
end)
local screenCinematic = cinematic
cinematic = function(p, id: string): boolean
	return screenCinematic(p, id) or (scenesPlayed[p] ~= nil and scenesPlayed[p][id] == true)
end
-- Lo que se dice en esas escenas (pista Dialogue/Lines) también cuenta para «said»: al lanzarse, se
-- resuelven sus variantes y condiciones con la partida del jugador (lo mismo que hace el servidor)
local HappeningServiceT = loadModule(ROOT .. "/server/Services/HappeningService")
local HappeningIndexT = loadModule(ROOT .. "/shared/LifeStory/HappeningIndex")
local SequencerT = loadModule(ROOT .. "/shared/LifeStory/Sequencer")
local sceneTexts: { [any]: { string } } = {}
local realPlay = HappeningServiceT.play
HappeningServiceT.play = function(p, id, opts)
	pcall(function()
		local def = HappeningIndexT.get(id)
		if def then
			local expanded = SequencerT.expand(def, SequencerT.resolve(def, HappeningServiceT.checker(p, opts)))
			sceneTexts[p] = sceneTexts[p] or {}
			for _, track in { "Dialogue", "Lines" } do
				for _, line in expanded.Tracks[track] or {} do
					table.insert(sceneTexts[p], line.T or line.Text or "")
				end
			end
		end
	end)
	return realPlay(p, id, opts)
end
local screenSaid = H.said
local function sceneSaid(p, fragment: string): boolean
	for _, text in sceneTexts[p] or {} do
		if text:find(fragment, 1, true) then
			return true
		end
	end
	return false
end
H.said = function(p, fragment: string): boolean
	return screenSaid(p, fragment) or sceneSaid(p, fragment)
end

---------------------------------------------------------------------
-- Pruebas
---------------------------------------------------------------------
print("\n▶ Datos de la historia")
local problems = loadModule(ROOT .. "/shared/LifeStory/Validate").run()
for _, problem in problems do
	print("    " .. problem)
end
check(#problems == 0, "Validate no encuentra errores")

print("\n▶ Días de cole: cada paso se puede completar (nadie falta, ninguna espera es eterna)")
do
	local DayPlans = loadModule(ROOT .. "/shared/LifeStory/DayPlans")
	local SchoolLife = loadModule(ROOT .. "/shared/LifeStory/SchoolLife")
	local LocationsMod = loadModule(ROOT .. "/shared/LifeStory/Locations")
	local QuestsMod = loadModule(ROOT .. "/shared/LifeStory/Quests")
	local secondsPerGameMinute = Config.DayLengthMinutes * 60 / 1440 / Config.SchoolDay.ClockSpeed
	local problemsFound = {}
	local function problem(text)
		if #problemsFound < 8 then
			table.insert(problemsFound, text)
		end
	end
	local lunches, recesses, days = 0, 0, 0
	for _, entry in { { Plan = "SchoolDay", Quest = "Nino_Jornada" }, { Plan = "HighSchoolDay", Quest = "Adol_Jornada" } } do
		local rng = TestRandom.new(7)
		local dialogues = QuestsMod[entry.Quest].Dialogues or {}
		for day = 1, 120 do
			local plan = DayPlans.generate(entry.Plan, rng)
			days += 1
			if not pcall(serde.encode, "json", plan.Steps) then
				problem(entry.Plan .. ": los pasos no se pueden guardar (JSON)")
			end
			for i, step in plan.Steps do
				local where = ("%s día %d paso %d (%s)"):format(entry.Plan, day, i, step.Type)
				if step.Place and not LocationsMod.Places[step.Place] and not tostring(step.Place):find("^%$") then
					problem(where .. ": lugar que no existe " .. tostring(step.Place))
				end
				for _, actor in step.Actors or {} do
					if not LocationsMod.Places[actor.Place] then
						problem(where .. ": actor en un lugar que no existe " .. tostring(actor.Place))
					end
				end
				if step.Type == "Talk" then
					-- El personaje está: lo trae la escena del paso o vive en el colegio (SchoolService)
					local inScene = false
					for _, actor in step.Actors or {} do
						inScene = inScene or actor.Npc == step.Npc
					end
					if not inScene and not SchoolLife.livesAtSchool(step.Npc) then
						problem(where .. ": nadie trae a " .. tostring(step.Npc))
					end
					if not inScene then
						problem(where .. ": " .. tostring(step.Npc) .. " no está en la escena del paso")
					end
					if step.Dialogue and not dialogues[step.Dialogue] then
						problem(where .. ": falta la conversación " .. tostring(step.Dialogue))
					end
					if not step.Dialogue then
						problem(where .. ": hablar sin conversación (no tendría plan B si no aparece)")
					end
				elseif step.Type == "Wait" then
					local minutes = step.GameMinutes or math.huge
					if minutes > DayPlans.MaxWaitMinutes or minutes * secondsPerGameMinute > DayPlans.MaxWaitSeconds then
						problem(where .. (": espera demasiado larga (%s min de juego)"):format(tostring(step.GameMinutes)))
					end
					if not step.MaxSeconds or step.MaxSeconds > DayPlans.MaxWaitSeconds then
						problem(where .. ": espera sin tope de tiempo real (MaxSeconds)")
					end
				elseif step.Type == "Event" and step.Event == "SchoolMeal" then
					if not (step.Timeout and step.Timeout.After and step.Timeout.After <= 120) then
						problem(where .. ": coger la bandeja sin plan B (Timeout)")
					end
				end
			end
			-- La comida: comedor con los compañeros sentados y la profe, bandeja, charla con el amigo y fin
			for i, step in plan.Steps do
				if step.Type == "Reach" and (step.Place == "ComedorColegio" or step.Place == "ComedorInstituto") then
					lunches += 1
					local meal, talk, rest = plan.Steps[i + 1], plan.Steps[i + 2], plan.Steps[i + 3]
					local names = {}
					for _, actor in step.Actors or {} do
						names[actor.Npc] = actor
					end
					local teacher = if entry.Plan == "HighSchoolDay" then "Javier" else "Lucia"
					if not (names.Nico and names.Sara and names.Omar and names[teacher]) then
						problem(entry.Plan .. ": en el comedor faltan compañeros o la profe")
					end
					if not (names.Nico and names.Nico.Mode == "Sit" and names.Nico.Work == "Eat") then
						problem(entry.Plan .. ": los compañeros no están sentados comiendo")
					end
					if not (meal and meal.Type == "Event" and meal.Event == "SchoolMeal" and talk and talk.Type == "Talk" and talk.Dialogue and rest and rest.Type == "Wait") then
						problem(entry.Plan .. ": la comida no es «bandeja → charla → terminar»")
					end
				elseif step.Type == "Talk" and step.Dialogue and step.Dialogue:find("^Ins_Recreo_") or (step.Type == "Talk" and step.Dialogue and step.Dialogue:find("^Recreo_")) then
					recesses += 1 -- (Ins_Recreo_*: las del instituto)
				end
			end
		end
	end
	for _, text in problemsFound do
		print("    " .. text)
	end
	check(#problemsFound == 0, ("%d días generados: todos los pasos existen, cada personaje está y cada espera tiene tope"):format(days))
	check(lunches == days and recesses == days, "Todos los días (cole e instituto) tienen recreo con un amigo y comida en el comedor")
	check(SchoolLife.activityAt(8.7) == "Llegada" and SchoolLife.activityAt(10) == "Clase" and SchoolLife.activityAt(11.7) == "Recreo" and SchoolLife.activityAt(14.5) == "Comedor" and SchoolLife.activityAt(16) == "Clase" and SchoolLife.activityAt(17.2) == "Salida" and SchoolLife.activityAt(22) == "Fuera", "Horario del colegio: puerta, clase, recreo, comedor, clase, salida y cerrado")
	check(SchoolLife.canEat("Nino", 14.5) and SchoolLife.canEat("Adolescente", 10) and not SchoolLife.canEat("Adulto", 14.5) and not SchoolLife.canEat("Nino", 21), "Comedor: gratis para niños y adolescentes con el cole abierto")
	local ready1 = SchoolLife.ready(nil, 100, 15)
	local ready2, left = SchoolLife.ready(100, 105, 15)
	check(ready1 and not ready2 and left == 10 and SchoolLife.ready(100, 116, 15), "Comedor: sin límite, solo una espera corta entre bandeja y bandeja")
	for _, where in { "AsientoComedor1", "AsientoInstituto1", "ProfeComedor", "ComedorInstituto", "BarraInstituto" } do
		local place = LocationsMod.Places[where]
		check(place and place.Fallback and LocationsMod.Places[place.Fallback], where .. " existe y tiene plan B en el mapa")
	end
	local Schedules = loadModule(ROOT .. "/shared/LifeStory/Schedules")
	check(Schedules.forPlace("ComedorInstituto") and Schedules.forPlace("ComedorInstituto").Id == "Instituto" and Schedules.forPlace("ComedorColegio").Id == "Colegio", "El comedor del instituto tiene el horario del instituto")
end

print("\n▶ Personajes vivos: gestos y emociones al hablar")
local Emotion = loadModule(ROOT .. "/shared/LifeStory/Emotion")
check(Emotion.of({ S = "Nico", T = "¡Hola, {nombre}!" }) == "Wave" and Emotion.of({ S = "Nico", T = "Jajaja, qué bueno" }) == "Laugh" and Emotion.of({ S = "Omar", T = "¡Hemos ganado!" }) == "Cheer", "Saludan, se ríen y celebran según lo que dicen")
check(Emotion.of({ S = "Abu", T = "Lo siento mucho, cariño." }) == "Sad" and Emotion.of({ S = "Sara", T = "¿Vienes?" }) == "Ask" and Emotion.of({ S = "Sara", T = "Mira, allí está." }) == "Point", "Tristes, preguntando o señalando")
check(Emotion.of({ S = "Nico", T = "Es un día normal." }) == "Calm" and Emotion.of({ S = "Narrador", T = "¡Hola!" }) == nil and Emotion.of({ S = "Nico", T = "Hola", A = "Dance" }) == "Dance", "Tono normal, el narrador sin gestos y A = … manda sobre el texto")
check(Emotion.valid("Cheer") and Emotion.valid("Thinking") and not Emotion.valid("Volar"), "Solo se aceptan gestos que existen")

print("\n▶ Estaciones y tiempo")
local Seasons = loadModule(ROOT .. "/shared/Seasons")
check(Seasons.seasonOf(1) == "Primavera" and Seasons.seasonOf(8) == "Verano" and Seasons.seasonOf(15) == "Otono" and Seasons.seasonOf(22) == "Invierno" and Seasons.seasonOf(29) == "Primavera", "Las estaciones van en orden, una por semana de juego")
local seen, snowOutsideWinter, sameTwice = {}, false, true
for dayN = 1, 112 do
	for hour = 0, 23, 6 do
		local w = Seasons.weatherAt(dayN, hour + 0.5)
		seen[w] = (seen[w] or 0) + 1
		if w == "Nieve" and Seasons.seasonOf(dayN) ~= "Invierno" then
			snowOutsideWinter = true
		end
		if Seasons.weatherAt(dayN, hour + 0.5) ~= w then
			sameTwice = false
		end
	end
end
check(seen.Despejado and seen.Nublado and seen.Lluvia and seen.Tormenta and seen.Nieve and seen.Niebla and not snowOutsideWinter, "Hay sol, nubes, lluvia, tormenta, niebla y nieve (la nieve solo en invierno)")
check(sameTwice and seen.Despejado > seen.Tormenta, "El tiempo es igual para todos (no cambia al volver a preguntar) y hace sol más a menudo que tormenta")
check(Seasons.label("Otono", "Lluvia") == "🍂 Otoño · 🌧️ Lluvia", "Etiqueta de la estación y el tiempo")
local Conditions = loadModule(ROOT .. "/shared/LifeStory/Conditions")
local ctxInvierno = { Stage = "Nino", ClockTime = 12, Weekday = 1, Completed = {}, Flags = {}, Choices = {}, Discovered = {}, Season = "Invierno", Weather = "Nieve" }
check(Conditions.check({ Season = "Invierno", Weather = { "Nieve", "Lluvia" } }, ctxInvierno) and not Conditions.check({ Season = "Verano" }, ctxInvierno), "Las misiones pueden depender de la estación y del tiempo")

-- Una clave repetida en una tabla de Luau no da error: la segunda borra a la primera sin avisar
local duplicated = {}
for _, name in { "Quests", "Chapters", "Locations", "Cinematics", "Subjects", "Strings", "ShopItems" } do
	local seen = {}
	for line in fs.readFile(ROOT .. "/shared/LifeStory/" .. name .. ".luau"):gmatch("[^\n]+") do
		local key = line:match("^\t([%w_]+) = ") or line:match('^\t%["([^"]+)"%] = ')
		if key then
			if seen[key] then
				table.insert(duplicated, name .. "." .. key)
			end
			seen[key] = true
		end
	end
end
for _, key in duplicated do
	print("    repetida: " .. key)
end
check(#duplicated == 0, "Ninguna misión, capítulo, lugar ni texto está repetido")

local GameClock = loadModule(ROOT .. "/shared/GameClock")
local date = GameClock.fromDay(30, 13.5)
check(date.Weekday == 2 and date.Month == 2 and date.DayOfMonth == 2 and date.Hour == 13 and date.Minute == 30, "GameClock: día 30 = martes 2 del mes 2, 13:30")
check(GameClock.isBetween(22, 6, 23) and GameClock.isBetween(22, 6, 3) and not GameClock.isBetween(22, 6, 12), "GameClock: horarios nocturnos")

local Service, StoryEvents, RoleService = H.boot()

print("\n▶ Roles: jugador o NPC")
local teacher = newPlayer("Profe", "Adulto")
local npc = RoleService.assign("Profesor", { Subject = "Matematicas" })
check(npc.Kind == "NPC" and npc.Npc == "Npc_Profesor", "Sin profesores conectados, la clase la da un NPC")
RoleService.setOnDuty(teacher, "Profesor", { Subject = "Matematicas" })
local real = RoleService.assign("Profesor", { Subject = "Matematicas" })
check(real.Kind == "Player" and real.Player == teacher, "Con un profesor jugador de servicio, la da él")
local other = RoleService.assign("Profesor", { Subject = "Musica" })
check(other.Kind == "NPC", "Para otra asignatura sigue habiendo NPC")
RoleService.release(real)
RoleService.offDuty(teacher)

print("\n▶ Las conversaciones no se repiten (toques de más, el toque que cierra una conversación)")
do
	local Guard = Service.Guard
	local rt = {}
	check(Guard.allow(rt, "Actor:Nico", 0) and not Guard.allow(rt, "Actor:Nico", 0.5) and Guard.allow(rt, "Actor:Nico", 1.3), "Dos toques seguidos al mismo personaje cuentan como uno")
	rt.DialogueEndedAt = 10
	check(not Guard.allow(rt, "Actor:Sara", 10.4) and Guard.allow(rt, "Actor:Sara", 11.5), "El toque que cierra una conversación no empieza otra")
	check(Guard.bark(rt, "Mateo", 0) and not Guard.bark(rt, "Mateo", 3) and Guard.bark(rt, "Mateo", 9), "Una frase suelta del mismo personaje, como mucho cada 8 s")
end

print("\n▶ Capítulo puente: una nueva vida en Valmar")
local ana = newPlayer("Ana", nil, 3600) -- ya jugaba antes de la historia de vida
task.wait(0.2)
local data = profiles[ana]
check(data.Life.Stage == "Adulto", "Un jugador veterano sigue siendo adulto")
check(cinematic(ana, "Adulto_Llegada"), "Empieza el capítulo con su cinemática")
check(data.Story.Active.Adulto_LlegadaValmar ~= nil, "Primera misión principal en marcha")
local state = lastState(ana)
check(state and state.Tracked and state.Tracked.TextKey == "QUEST.LLEGADA.PLAZA" and state.Tracked.Args.placeKey == "PLACE.PLAZA_CENTRO", "La tarjeta dice 'Ve a la Plaza Mayor'")

ana.At = "PlazaCentro"
task.wait(0.7)
check(data.Story.Active.Adulto_LlegadaValmar.Step >= 2, "Llegar a la plaza avanza al siguiente paso")
-- (en la plaza, Ernesto y Lola te dan la bienvenida: escena Adulto_Bienvenida)
for _ = 1, 40 do
	if data.Story.Active.Adulto_LlegadaValmar.Step >= 3 then
		break
	end
	task.wait(0.2)
end
check(data.Story.Active.Adulto_LlegadaValmar.Step == 3, "Ernesto y Lola te dan la bienvenida en la plaza")
StoryEvents.emit(ana, "HomeClaimed", {})
StoryEvents.emit(ana, "Ate", {})
task.wait(0.1)
check(data.Story.Completed.Adulto_LlegadaValmar ~= nil, "Conseguir casa y comer completa 'Llegar a Valmar'")
check(data.Money == 100 and data.Story.Flags.TieneHogar, "Recompensa: dinero y marca TieneHogar")
check(received(ana, "Moment", "MOMENT.PRIMER_HOGAR"), "Momento de vida: 'Ya tienes un hogar en Valmar'")
check(momentSting(ana, "MOMENT.PRIMER_HOGAR") == "Momento", "El momento suena con su efecto")
check(data.Story.Active.Adulto_PrimerSueldo ~= nil, "Empieza 'Ganarte la vida'")

StoryEvents.emit(ana, "JobTaskDone", { JobId = "Barista" })
StoryEvents.emit(ana, "JobTaskDone", { JobId = "Barista" })
task.wait(0.1)
state = lastState(ana)
check(state.Tracked.Args.count == 2 and state.Tracked.Args.total == 3, "La tarjeta cuenta 2/3 entregas")
StoryEvents.emit(ana, "JobTaskDone", { JobId = "Barista" })
task.wait(0.1)
check(data.Story.Completed.Adulto_PrimerSueldo ~= nil and data.Money == 250, "Tres entregas: primer sueldo celebrado")

print("\n▶ Secundaria que nace de lo que haces (repartir)")
StoryEvents.emit(ana, "JobTaskDone", { JobId = "Repartidor" })
task.wait(0.1)
check(received(ana, "Offer", "QUEST.MEDICINAS.TITLE"), "Correos te pide llevar medicinas")
fromClient(ana, "Offer", "Side_MedicinasUrgentes", true)
check(data.Story.Active.Side_MedicinasUrgentes ~= nil, "Aceptada: la secundaria está en marcha")
check(data.Story.Active.Adulto_ConoceLaRegion ~= nil, "La principal sigue en paralelo")

print("\n▶ Decisión con ramas")
check(received(ana, "Choice"), "Se pregunta adónde ir en el día libre")
fromClient(ana, "Choose", "Adulto_ConoceLaRegion", "Playa")
check(data.Story.Choices.PrimeraExcursion and data.Story.Choices.PrimeraExcursion.V == "Playa", "La decisión queda guardada")
ana.At = "CentroSalud"
task.wait(0.7)
check(data.Story.Completed.Side_MedicinasUrgentes ~= nil and data.Money == 310, "Medicinas entregadas (+60)")
ana.At = "ParadaBus"
task.wait(0.7)
local step = data.Story.Active.Adulto_ConoceLaRegion and data.Story.Active.Adulto_ConoceLaRegion.Step
check(step == 4, "La rama 'campus' se salta: toca ir a la playa (paso 4)")
ana.At = "Playa"
task.wait(0.7)
check(data.Story.Completed.Adulto_ConoceLaRegion ~= nil, "Llegar a la playa completa la excursión")
check(data.Story.Chapters.Adulto_NuevaVida ~= nil and cinematic(ana, "Adulto_TuCiudad"), "Capítulo terminado con su cinemática de cierre")
check(data.Story.Discovered.Playa and data.Story.Discovered.PlazaCentro, "Los lugares visitados quedan descubiertos")
local biography = {}
for _, event in data.Story.Events do
	table.insert(biography, event.K)
end
check(table.find(biography, "MOMENT.PRIMER_SUELDO") ~= nil and table.find(biography, "QUEST.REGION.OPT_PLAYA") ~= nil, "La biografía guarda momentos y decisiones")
check(pcall(serde.encode, "json", data), "Los datos se pueden guardar (JSON válido)")

print("\n▶ Fase 2: nacer, aprender a caminar, explorar la casa y crecer")
local leo = newPlayer("Leo") -- personaje nuevo
task.wait(0.2)
local leoData = profiles[leo]
check(leoData.Life.Stage == "Bebe" and leo:GetAttribute("LifeStage") == "Bebe", "Un personaje nuevo nace bebé")
check(cinematic(leo, "Bebe_NacimientoCuna"), "Empieza con la escena del nacimiento (la cuna)")
check(lastState(leo).ChapterMusic == "Nacimiento", "Suena la nana de fondo en casa")
check(leoData.Story.Active.Bebe_AprendeACaminar ~= nil, "Primera misión: aprende a caminar")
StoryEvents.emit(leo, "BabyStood", {})
for _ = 1, 4 do
	StoryEvents.emit(leo, "BabySteps", {})
end
task.wait(0.1)
state = lastState(leo)
check(state.Tracked.Args.count == 4 and state.Tracked.Args.total == 5, "La tarjeta cuenta los pasos (4/5)")
StoryEvents.emit(leo, "BabySteps", {})
task.wait(0.7)
state = lastState(leo)
check(state.Tracked.TextKey == "QUEST.BEBE_CAMINAR.S3" and leo:GetAttribute("StoryTarget") ~= nil, "Toca llegar hasta Abu, con línea guía hasta él")
StoryEvents.emit(leo, "Talk", { Npc = "Familia_Padre" })
task.wait(0.1)
check(leoData.Story.Active.Bebe_AprendeACaminar ~= nil, "Hablar con otra persona no cuenta como llegar hasta Abu")
StoryEvents.emit(leo, "Talk", { Npc = "Familia_Abu" })
task.wait(0.1)
check(cinematic(leo, "Bebe_PrimerosPasosAbu") and leoData.Story.Active.Bebe_AprendeACaminar ~= nil, "Cinemática de primeros pasos (la historia espera a que acabe)")
task.wait(6.3)
check(leoData.Story.Completed.Bebe_AprendeACaminar ~= nil and received(leo, "Moment", "MOMENT.PRIMEROS_PASOS"), "Momento: 'Has dado tus primeros pasos'")
check(momentSting(leo, "MOMENT.PRIMEROS_PASOS") == "ninguno", "Sin efecto repetido (la cinemática ya tiene su música)")

StoryEvents.emit(leo, "BabyInteract", { Object = "Tele" })
leo.At = "HomeCocina"
task.wait(0.7)
state = lastState(leo)
check(state.Tracked.Children and state.Tracked.Children[1].Done and state.Tracked.Children[2].Done and not state.Tracked.Children[3].Done, "Explorar la casa: cocina y tele sí, bloques todavía no (en cualquier orden)")
StoryEvents.emit(leo, "BabyInteract", { Object = "Juguetes" })
task.wait(0.7)
state = lastState(leo)
check(state.Tracked.TextKey == "QUEST.BEBE_CASA.S2", "Después: pedir el biberón a la familia")
StoryEvents.emit(leo, "Talk", { Npc = "Familia_Padre" })
task.wait(0.1)
check(leoData.Story.Completed.Bebe_ExploraLaCasa ~= nil, "Casa explorada y familia conocida")
StoryEvents.emit(leo, "LookedOutside", {})
task.wait(0.3)
check(cinematic(leo, "Montaje_Bebe_Nino"), "Mirar por el ventanal lleva al montaje de cambio de etapa (bebé → niño)")
check(leoData.Life.Stage == "Nino" and leo:GetAttribute("LifeStage") == "Nino", "Ahora es niño")
check(leoData.Story.Chapters.Bebe_PrimerosPasos ~= nil, "Capítulo de bebé terminado")
check(cinematic(leo, "Cole01_Amanecer") and leoData.Story.Active.Cole01_PrimerDia ~= nil, "Empieza el colegio con la misión «El primer día» (amanece en Los Pinos)")
check(leoData.Life.AgeYears == 6 and leo:GetAttribute("AgeYears") == 6, "Tiene 6 años")
check(pcall(serde.encode, "json", leoData), "Los datos del bebé se pueden guardar (JSON válido)")

---------------------------------------------------------------------
-- Jugador automático (lib/StoryHarness)
---------------------------------------------------------------------
local Quests, Subjects, HOURS = H.Quests, H.Subjects, H.HOURS
local preferAnswer, questStep, mainStep, doStep = H.preferAnswer, H.questStep, H.mainStep, H.doStep
local playUntil, playQuest, said, classesOf, laterStarts, passTime = H.playUntil, H.playQuest, H.said, H.classesOf, H.laterStarts, H.passTime

-- Escenas del motor (Happenings) que ve cada jugador: sus frases no pasan por las conversaciones, así
-- que se apunta qué escena se lanza (HappeningService.play)
local Happening = H.loadModule(H.ROOT .. "/server/Services/HappeningService")
local happeningPlay = Happening.play
Happening.play = function(player, id, ...)
	player.Scenes = player.Scenes or {}
	table.insert(player.Scenes, id)
	return happeningPlay(player, id, ...)
end
local function scene(player, id: string): boolean
	return table.find(player.Scenes or {}, id) ~= nil
end

---------------------------------------------------------------------
print("\n▶ Misión 01 «El primer día» (casa, camino, entrada, colegio, clase, recreo, cena)")
lighting.ClockTime = 9
leo.Prefer = { "¡Ya voy!", "Sudadera", "¡Claro!", "Fruta", "Me alegro", "acompáñame", "Me encanta explorar", "experimentos", "Yo vigilo", "Mañana te sientas", "He hecho un amigo" }
leo.Picks = { Asiento = "Sara", GrupoRecreo = "Estudiantes" }
local scene1 = scenes[leo] and scenes[leo].Cole01_PrimerDia
check(scene1 and scene1.Actors.Familia and scene1.Actors.Abu, "Escena 1: {familia} te despierta en tu cuarto y Abu está en el salón")
check(leo.At == "HomeDormitorio", "Empiezas en tu dormitorio")
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole01_PrimerDia ~= nil
end), "Misión 01 completa, de principio a fin")
local memories = leoData.Story.Memories
check(memories.PrimerDiaCole and memories.PrimerAmigo, "Recuerdos: «Tu primer día de colegio» y «tu primer amigo»")
check(leoData.Items.MochilaCole == 1 and leoData.Items.CromoSuerte == 1, "La mochila del cole y el cromo de la suerte están en la mochila (inventario)")
check(leoData.Story.Choices.Ropa.V == "Sudadera" and leoData.Story.Choices.Acompanante.V == "Familia", "Elegiste ropa y que te acompañaran")
check(leoData.Story.Flags.PaseADani and said(leo, "¡Qué pase!"), "Minijuego del balón de Dani: pase acertado y Dani lo celebra")
check(leo.Emotions["Mochila nueva. Profe nueva. Compañeros nuevos."] == "Happy", "Cada frase llega al cliente con su gesto (la familia, contenta)")
check(said(leo, "¿Fuiste tú quien le pasó el balón a mi hermano"), "Mateo recuerda el balón de su hermano (diálogo que depende de lo que hiciste)")
check(leoData.Story.Choices.Asiento.V == "Sara" and said(leo, "Aquí delante se entiende todo"), "Te sientas junto a Sara (se elige tocando la silla)")
check(leoData.Story.Choices.Gusto.V == "Ciencia" and said(leo, "Tenemos que hablar"), "Te presentas: te gustan los experimentos")
check(leoData.Story.Choices.GrupoRecreo.V == "Estudiantes" and said(leo, "Estás dentro"), "En el recreo vas con Sara e Iker, que recuerdan lo que dijiste en clase")
check(classesOf(leo)[1] == "Matematicas", "Clase de Matemáticas jugable")
check(leoData.Story.Flags.AyudasteAMateo and (leoData.Story.NpcMemory.Mateo.Rel or 0) >= 15, "Ayudas a Mateo con sus libros: relación +")
check(said(leo, "El que ayuda nunca está solo."), "En la cena, Abu recuerda su consejo")
check(laterStarts(leo).Eco_MateoDibujo ~= nil, "Consecuencia programada: Mateo te buscará dentro de un rato")
check((leoData.Story.Traits.Responsabilidad or 0) >= 1 and (leoData.Story.Traits.Curiosidad or 0) >= 1, "Tus respuestas suben rasgos (responsabilidad, curiosidad…)")
check(received(leo, "Moment", "Tu primer día de colegio"), "Momento final: «Tu primer día de colegio»")
check(scenes[leo].Cole01_PrimerDia == nil, "Al terminar, sus actores y objetos se van")
check(pcall(serde.encode, "json", leoData), "Todo se puede guardar (JSON válido)")

task.wait(0.8)
local jornada = leoData.Story.Active.Nino_Jornada
check(jornada ~= nil and jornada.Steps and #jornada.Steps >= 4, "Hasta la siguiente misión, días de cole normales")
check(leoData.Story.Active.Cole02_Mochila == nil, "«La mochila desaparecida» espera su momento de la etapa")

print("\n▶ Un día de cole jugado entero: recreo, comedor con los compañeros y la profe, bandeja, charla")
do
	local story = leoData.Story
	local sawLunch, sawTeacher, shortWait, sawRecess = false, false, false, false
	leo.Answer = preferAnswer(leo)
	for _ = 1, 200 do
		if story.Completed.Nino_Jornada ~= nil then
			break
		end
		local prog = story.Active.Nino_Jornada
		local step = prog and prog.Steps and prog.Steps[prog.Step]
		if step then
			local scene = scenes[leo] and scenes[leo].Nino_Jornada
			if step.Type == "Event" and step.Event == "SchoolMeal" and scene then
				sawLunch = sawLunch or (scene.Actors.Nico ~= nil and scene.Actors.Sara ~= nil and scene.Actors.Omar ~= nil and scene.Actors.Nico.Mode == "Sit")
				sawTeacher = sawTeacher or scene.Actors.Lucia ~= nil
			elseif step.Type == "Talk" and step.Dialogue and step.Dialogue:find("^Recreo_") and scene then
				sawRecess = sawRecess or scene.Actors[step.Npc] ~= nil
			end
			if step.Type == "Wait" and step.TextKey == "QUEST.COLE.COMIENDO" then
				-- Aunque el reloj del juego no avance (como el bug de las 9:00), la comida se acaba sola
				step.MaxSeconds = 1
				local index = prog.Step
				task.wait(1.4 + Config.LifeStory.TickSeconds)
				local now = story.Active.Nino_Jornada
				shortWait = now == nil or now.Step ~= index
			else
				doStep(leo, "Nino_Jornada", step)
			end
		end
		task.wait(0.6)
	end
	check(story.Completed.Nino_Jornada ~= nil, "El día de cole se completa de principio a fin")
	check(sawRecess, "En el recreo, tu amigo del día está en el patio (la escena lo trae)")
	check(sawLunch and sawTeacher, "En el comedor están Nico, Sara y Omar sentados comiendo, y la profe de guardia")
	check(said(leo, "Te he guardado sitio") or said(leo, "contando los guisantes") or said(leo, "le falta un poco de comino"), "Coges la bandeja, te sientas y hablas con tu amigo (conversación del comedor)")
	check(shortWait, "«Terminad de comer» se acaba aunque el reloj esté parado (tope de tiempo real)")
	check(pcall(serde.encode, "json", leoData), "El día de cole se puede guardar (JSON válido)")
end

print("\n▶ Consecuencia diferida: una hora después, Mateo te busca")
check(leoData.Story.Active.Nino_Jornada == nil and leoData.Story.LoopDay == H.getDay(), "Un día de cole por día de juego: hoy ya no empieza otro")
H.nextSchoolDay() -- (el siguiente, mañana)
passTime(leo, 3700)
check(leoData.Story.Active.Eco_MateoDibujo ~= nil, "Pasada una hora de juego, empieza «Un regalo de Mateo»")
state = lastState(leo)
-- (se puede hacer ahora: la que sigues o una opcional sin «para luego»)
local function showsQuest(questId: string): boolean
	if state.Tracked and state.Tracked.QuestId == questId then
		return true
	end
	for _, other in state.Others do
		if other.QuestId == questId and not other.Later then
			return true
		end
	end
	return false
end
local function laterQuest(questId: string): string?
	for _, other in state.Others do
		if other.QuestId == questId then
			return other.Later
		end
	end
	return nil
end
check(showsQuest("Nino_Jornada") and not showsQuest("Eco_MateoDibujo"), "En horario de cole solo se hacen las misiones del cole")
check(laterQuest("Eco_MateoDibujo") == "AfterSchool", "…pero las demás siguen en la lista, marcadas «después del cole» (no desaparecen)")
lighting.ClockTime = 18
task.wait(Config.LifeStory.RefreshSeconds + 0.6)
state = lastState(leo)
check(not showsQuest("Nino_Jornada") and state.Tracked and state.Tracked.QuestId == "Eco_MateoDibujo", "Al acabar el cole, el día de cole espera y se sigue la misión de Mateo")
check(laterQuest("Nino_Jornada") == "School", "…y el día de cole sigue en la lista, marcado «en horario de cole»")
lighting.ClockTime = 9
check(playQuest(leo, "Eco_MateoDibujo"), "Hablas con Mateo")
check(leoData.Items.DibujoMateo == 1, "Te regala su dibujo (va a tu mochila)")

print("\n▶ Misión 02 «La mochila desaparecida» (investigación, canastas, almacén, decisión)")
leo.Prefer = { "¿Y dónde van", "Gracias por contármelo", "Perdonarle" }
leoData.Life.StageSeconds = 0.09 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole02_Mochila ~= nil
end), "Misión 02 completa")
check(said(leo, "Mi mochila.") and leoData.Items.MochilaCole == 1, "La mochila desaparece del inventario… y vuelve al final")
check(said(leo, "Fue Rubén."), "Mateo (tu amigo) te da una pista extra")
check(leoData.Story.Flags.PistaR and leoData.Story.Flags.PistaB, "Pistas del patio: la «R» y el llavero de la «B»")
local basket = nil
for _, spec in leo.Games do
	if spec.Title == "¡Mete 3 canastas!" then
		basket = spec
	end
end
check(basket and basket.Rounds == 8 and leoData.Story.Flags.CanastasAlex, "Minijuego: 3 canastas para que Álex hable")
check(leoData.Story.Choices.MochilaRuben.V == "Perdon" and leoData.Story.Flags.Ruben_Perdonado, "Decisión: perdonas a Rubén")
check(said(leo, "Un balón azul con forma de mochila"), "Lucía reacciona según tu decisión")
check(leoData.Story.Memories.MochilaPerdida ~= nil, "Recuerdo: «El día que desapareció tu mochila»")
check(laterStarts(leo).Eco_Ruben ~= nil and laterStarts(leo).Eco_Ruben.At >= leoData.Story.Clock + 9.9 * 3600, "Consecuencia programada para dentro de 10 horas de juego")

print("\n▶ Misión 03 «El grupo» (invitaciones, partido, parque, sueños, nombre del grupo)")
leo.Prefer = { "Como las pompas", "Delante", "Lo mejor ha sido jugar juntos", "Primero pido permiso", "Tiro lejano", "La hoja y la piña", "¡Invito yo", "Inventar cosas", "¡Claro! Mañana", "La Patrulla Valmar" }
leo.Picks = { Invitacion = "Sara" }
leo.Skip = { Columpio = true } -- en el parque: canasta, estanque y helados (3 de 4)
local moneyBefore = leoData.Money
leoData.Life.StageSeconds = 0.14 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole03_Grupo ~= nil
end), "Misión 03 completa")
check(leoData.Story.Choices.Invitacion.V == "Sara" and said(leo, "Registro científico número uno"), "Vas con Sara a seguir al escarabajo (3 sitios del colegio)")
local match = nil
for _, spec in leo.Games do
	if spec.Game == "Futbol" then
		match = spec
	end
end
check(match and match.Position == "Delantero", "Partido de fútbol jugable como delantero (la posición elegida cambia el minijuego)")
check(leoData.Story.Flags.PartidoGanado and said(leo, "¡HEMOS GANADO A BRUNO!"), "Ganáis el partido y el banquillo lo celebra")
check(said(leo, "Buen partido."), "Hugo se acerca (semilla de la misión 04)")
check(said(leo, "¿Ya tienes amigos?"), "Pides permiso en casa antes de ir al parque")
check(leoData.Money == moneyBefore - 8, "Invitas a helados a todos (8 $)")
check(leoData.Story.Choices.SuenoInfancia.V == "Ingenieria" and leoData.Story.Memories.SuenoDeMayor, "Tu sueño de mayor queda guardado (volverá en el instituto)")
check(leoData.Story.Choices.NombreGrupo.V == "La Patrulla Valmar" and said(leo, "¡Me encanta!"), "El grupo se llama «La Patrulla Valmar» y los amigos lo dicen")
check(leoData.Items.FotoGrupo == 1 and leoData.Items.CuadernoOmar == 1, "Foto del grupo y dibujo de Omar en la mochila")
check(cinematic(leo, "Cole03_Foto"), "Foto final (cinemática)")
check(leoData.Story.Memories.PrimerGrupo and leoData.Story.Memories.PrimerPartido, "Recuerdos: tu grupo y tu primer partido")

print("\n▶ Secundaria que nace de una conversación: el gato del colegio")
passTime(leo, 200)
check(leoData.Story.Active.Side_GatoDelCole ~= nil, "Omar y tú vais a buscar a Bigotes")
check(playQuest(leo, "Side_GatoDelCole"), "Seguís las huellas y lo encontráis")
check(said(leo, "¡Bigotes es mamá!") and leoData.Story.Memories.GatoDelCole, "¡Bigotes tenía gatitos! (recuerdo nuevo)")

print("\n▶ 10 horas de juego después: Rubén vuelve")
passTime(leo, 10 * 3600)
check(leoData.Story.Active.Eco_Ruben ~= nil, "Rubén aparece")
check(playQuest(leo, "Eco_Ruben"), "Hablas con Rubén")
check(said(leo, "Fuiste la única persona que me perdonó") and not said(leo, "Me acuerdo de cómo me gritaste"), "Su conversación depende de que le perdonaste hace 10 horas")

print("\n▶ Otro camino: ignorar a Mateo el primer día")
local noa = newPlayer("Noa", "Nino")
local noaData = profiles[noa]
task.wait(0.3)
noa.Prefer = { "Cinco minutitos", "dinosaurios", "Mejor no", "Tostadas", "Voy yo solo", "Ha sido un rollo" }
noa.Picks = { Asiento = "Nico", GrupoRecreo = "Deportistas" }
noa.GameResult = { Hits = 0 } -- falla el pase a Dani
noa.Skip = { Libro1 = true, Libro2 = true, Libro3 = true, Libro4 = true }
local booksStep = nil
for i, step in Quests.Cole01_PrimerDia.Steps do
	if step.Timeout then
		booksStep = step
	end
end
local originalAfter = booksStep.Timeout.After
booksStep.Timeout.After = 2 -- en la prueba no se espera 45 s
check(playUntil(noa, function()
	return noaData.Story.Completed.Cole01_PrimerDia ~= nil
end), "Misión 01 completa por otro camino")
booksStep.Timeout.After = originalAfter
check(noaData.Story.Flags.FallastePase and said(noa, "Se ha ido a la farola."), "Falla el pase: Dani se ríe y la historia sigue (nunca bloquea)")
check(noaData.Story.Flags.IgnorasteAMateo and (noaData.Story.NpcMemory.Mateo.Rel or 0) < 10, "Si no le ayudas, Mateo recoge solo sus cosas")
check(said(noa, "Mañana, si lo ves solo…"), "En la cena, la familia te lo comenta")
check(not noaData.Story.Memories.PrimerAmigo and laterStarts(noa).Eco_MateoSolo ~= nil, "Sin «primer amigo»… pero con una segunda oportunidad programada")
passTime(noa, 3700)
check(noaData.Story.Active.Eco_MateoSolo ~= nil, "Una hora después, ves a Mateo comiendo solo")
check(playQuest(noa, "Eco_MateoSolo") and noaData.Story.Memories.SegundaOportunidad and noaData.Story.Flags.AyudasteAMateo, "Te sientas con él: ahora sí sois amigos")
do
	local function count(fragment)
		local n = 0
		for _, text in noa.Said do
			if text:find(fragment, 1, true) then
				n += 1
			end
		end
		return n
	end
	Service.interact(noa, "Actor", "Eco_MateoSolo", "Mateo")
	task.wait(1.5)
	Service.interact(noa, "Actor", "Eco_MateoSolo", "Mateo")
	task.wait(0.5)
	check(count("¿Conmigo? Vale. Sí. Claro.") == 1, "Lo de Mateo («…¿Conmigo? Vale.») se dice una sola vez: al volver a tocarle no se repite")
end

print("\n▶ Misión 04 «Los malotes» (burlas, objeto robado, persecución, Hugo, decisión)")
leo.Prefer = { "Por lo menos nosotros", "Pedir ayuda a mi grupo" }
leo.Picks = {}
leo.Skip = {}
leoData.Life.StageSeconds = 0.19 * HOURS.Nino * 3600
local cromoAntes = leoData.Items.CromoSuerte
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole04_Malotes ~= nil
end), "Misión 04 completa")
check(said(leo, "¿Dónde está mi cromo de la suerte?") and leoData.Items.CromoSuerte == cromoAntes, "Te quitan tu cromo de la suerte (el objeto que llevabas desde el primer día) y lo recuperas")
check(scene(leo, "Cole04_LosVes"), "Persecución: los pillas con lo tuyo y salen corriendo (escena Cole04_LosVes)")
check(said(leo, "Serán los gatos."), "Te escondes de Ramón a tiempo")
check(said(leo, "Bruno dijo:") and said(leo, "¿La isla de las mil llaves?"), "Hugo no quería participar (y recuerda que viste su libro en el almacén)")
check(leoData.Story.Choices.Malotes.V == "Grupo" and leoData.Story.Flags.HugoConElGrupo and said(leo, "Y estamos hartos."), "Decisión: tu grupo se planta contigo; Hugo se queda con vosotros")
check(leoData.Story.Memories.LosMalotes ~= nil and laterStarts(leo).Eco_Hugo ~= nil, "Recuerdo «Los malotes» y consecuencia programada con Hugo")
leo.Prefer = { "¿Por qué no te vienes" }
passTime(leo, 2 * 3600 + 100)
check(leoData.Story.Active.Eco_Hugo ~= nil and playQuest(leo, "Eco_Hugo"), "Dos horas después, Hugo te busca")
check(said(leo, "portero suplente") and leoData.Items.LibroPiratas == 1 and leoData.Story.Memories.HugoAmigo, "Te regala su libro de piratas y se une al grupo")

print("\n▶ Misión 05 «La venganza de la mochila» (pistas, acusar, confesión)")
leo.Prefer = { "Vente con nosotros" }
leo.Picks = {
	Culpable = function(story)
		return if story.Flags.AcusasteABruno then "Iker" else "Bruno" -- primero se equivoca
	end,
}
leoData.Life.StageSeconds = 0.25 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole05_Venganza ~= nil
end), "Misión 05 completa")
check(said(leo, "¡Esta vez NO he sido yo!") and not said(leo, "Tú hablaste conmigo"), "Todos culpan a Bruno (y no dice «tú hablaste conmigo»: en la misión 04 fuiste con tu grupo, no a hablar con él)")
check(said(leo, "Lunes — 11:05 — Iker."), "Pistas: el registro de salidas al baño")
check(leoData.Story.Flags.AcusasteABruno and said(leo, "¡Por una vez que no hago nada!"), "Acusar a quien no era tiene consecuencias (y la decisión sigue abierta)")
check(leoData.Story.Choices.Culpable.V == "Iker" and said(leo, "Iker no necesitaba hacer una broma"), "Descubres a Iker y por qué lo hizo")
check(leoData.Story.Flags.IkerEnElGrupo and leoData.Items.Lupa == 1 and said(leo, "Me acusaste sin pruebas"), "Iker entra en el grupo, Lucía te da su lupa y Bruno se acuerda")

print("\n▶ Misión 06 «El examen imposible» (apuntes, estudiar, la noche antes, examen)")
leo.Prefer = { "Pedir ayuda a Abu" }
leo.Picks = { CompaneroEstudio = "Mateo" }
leo.ClassGrade = 3 -- esta vez sale mal
leoData.Life.StageSeconds = 0.31 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole06_Examen ~= nil
end), "Misión 06 completa")
check(said(leo, "Más o menos.") and said(leo, "Eso significa que no."), "Estudias con Mateo (diálogo con personalidad)")
check(said(leo, "contábamos con garbanzos") and leoData.Story.Flags.EstudiasteMas, "La noche antes, Abu te ayuda a repasar")
local examExtra = nil
for _, call in classCalls do
	if call.Player == leo and call.Mode == "Examen" then
		examExtra = call.Extra
	end
end
check(examExtra == 6, "Haber estudiado da 6 segundos más por pregunta en el examen")
check(leoData.Story.Flags.SuspendisteExamen and said(leo, "un examen no dice quién eres"), "Suspendes… y Lucía te ofrece otra oportunidad")
check(leoData.Items.ApuntesBiblioteca == nil, "Devuelves los apuntes a Marisa")
leo.ClassGrade = 7
passTime(leo, 90)
check(leoData.Story.Active.Cole06b_Recuperacion ~= nil and playQuest(leo, "Cole06b_Recuperacion"), "Recuperación con Lucía")
check(said(leo, "No era que no pudieras") and leoData.Story.Memories.CasiSuspendo, "Apruebas la recuperación: recuerdo «Aquel examen que casi suspendes»")
leo.ClassGrade = nil

print("\n▶ Misión 07 «La excursión» (autobús, granja, alguien se pierde, foto)")
leo.Prefer = { "Le das la mano" }
leo.Picks = { AsientoBus = "Mateo" }
leoData.Life.StageSeconds = 0.45 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole07_Excursion ~= nil
end), "Recados y misión 07 completos")
check(leoData.Story.Completed.Nino_Recados ~= nil, "Los recados van antes de la excursión")
check(said(leo, "Nunca he ido de excursión") and leoData.Story.Choices.AsientoBus.V == "Mateo", "Te sientas con Mateo en el autobús (y el viaje lo recuerda)")
check(cinematic(leo, "Cole07_Viaje") and cinematic(leo, "Cole07_Foto"), "Cinemáticas del viaje y de la foto")
check(said(leo, "Falta Mateo") and said(leo, "«¡Le sigo!»"), "¡Falta Mateo! Las pistas llevan al granero")
check(leoData.Story.Choices.Rescate.V == "Juntos" and said(leo, "Iba detrás de Copito."), "Le das la mano y volvéis juntos")
check(leoData.Items.FotoExcursion == 1 and leoData.Story.Memories.PrimeraExcursion ~= nil and said(leo, "¡Empieza el torneo del colegio!"), "Foto de la excursión, recuerdo, y Andrés anuncia el torneo")

print("\n▶ Misión 08 «El torneo» (deporte, capitán, clasificación, grada, final)")
leo.Prefer = { "Omar. Hace falta", "Que juegue todo el mundo", "Me tiemblan", "Que gane el mejor", "Dar la mano" }
leo.Picks = { Deporte = "Atletismo" }
leo.GameResult = { Hits = 1 } -- esta vez las carreras salen mal
local circuitos = 0
for _, call in classCalls do
	if call.Player == leo and call.Mode == "Circuito" then
		circuitos += 1
	end
end
leoData.Life.StageSeconds = 0.55 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole08_Torneo ~= nil
end), "Misión 08 completa")
local circuitosDespues = 0
for _, call in classCalls do
	if call.Player == leo and call.Mode == "Circuito" then
		circuitosDespues += 1
	end
end
check(said(leo, "ahora lo haremos A PROPÓSITO") and circuitosDespues == circuitos + 1, "Eliges atletismo: entrenas el circuito de la pista")
check(not said(leo, "Entrenamiento: tiros libres") and leoData.Story.Choices.Capitan.V == "Omar" and leoData.Story.Choices.Estrategia.V == "Todos", "Omar es el capitán y juega todo el mundo")
check(said(leo, "pasáis como mejor segundo"), "Pierdes la clasificación pero pasas como mejor segundo")
check(said(leo, "Mira, el detective") and said(leo, "Juego con ellos."), "Bruno recuerda que le acusaste; Hugo se planta")
check(leoData.Story.Flags.TorneoPerdido and leoData.Items.MedallaPlata == 1 and said(leo, "Me das la mano después de perder"), "Final perdida: medalla de plata y das la mano")
check(leoData.Story.Memories.PrimerTorneo ~= nil and said(leo, "la puerta del fondo del pasillo"), "Recuerdo del torneo y el rumor de la sala cerrada")
leo.GameResult = nil

print("\n▶ Misión 09 «El misterio del colegio» (nota, pistas, candado, la foto, Lucía)")
leo.Prefer = { "Guardar el secreto" }
leo.Picks = {
	Entrar = "Colarse",
	Candado = function()
		return if said(leo, "Lo has puesto al revés") then "199813" else "131998" -- primero se equivoca
	end,
	Capsula = "Pregunta",
}
leoData.Life.StageSeconds = 0.63 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole09_Misterio ~= nil
end), "Misión 09 completa")
check(said(leo, "NO ENTRES EN LA SALA DEL FONDO") and said(leo, "He creado un expediente."), "La nota en la taquilla (e Iker abre un caso)")
check(said(leo, "La número 13 no se toca.") and said(leo, "¡1998!"), "Pistas: la llave 13 y el año 1998")
check(leoData.Story.Choices.Candado.V == "199813" and said(leo, "¡CLAC!"), "Un código mal no abre; el bueno sí")
check(said(leo, "¡Ajá!") and scene(leo, "Cole09_LaFoto"), "Te cuelas, Ramón te pilla… y encontráis la foto de Lucía (escena Cole09_LaFoto)")
check(leoData.Story.Flags.SecretoLucia and leoData.Story.Flags.CapsulaDelTiempo and leoData.Story.Choices.Capsula.V == "Pregunta", "Guardas el secreto y metes tu pregunta en la cápsula del tiempo")
check(leoData.Items.FotoLucia == 1 and leoData.Story.Memories.MisterioColegio ~= nil, "Copia de la foto y recuerdo del misterio")

print("\n▶ Misión 10 «El festival» (tarea, imprevistos, Bruno, escenario)")
leo.Prefer = { "Te agachas", "Le ayudas", "Subo a contar chistes" }
leo.Picks = { Festival = "Teatro" }
leo.Skip = { Farolillos = true } -- deja los farolillos a otros: resuelve los otros tres imprevistos
leoData.Life.StageSeconds = 0.73 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole10_Festival ~= nil
end), "Misión 10 completa")
check(said(leo, "Nico hará de loro") and said(leo, "Nunca nadie había querido hacer una obra mía."), "Eliges el teatro con Hugo (solo si Hugo está en tu grupo) y la obra sale")
check(said(leo, "Desenchufado.") and leoData.Story.Choices.NinaPerdida.V == "Juntos", "Imprevistos: el altavoz y la niña perdida")
check(leoData.Story.Choices.FestivalBruno.V == "Ayudar" and said(leo, "Gracias. En voz baja.") and said(leo, "El puesto ha funcionado."), "Ayudas a Bruno con su puesto (y lo dice delante de todos)")
check(leoData.Story.Flags.SubesAlEscenario and said(leo, "¿Por qué el libro de mates está triste?"), "Subes al escenario con Nico y el público aplaude")
check(cinematic(leo, "Cole10_Festival") and leoData.Items.FotoFestival == 1 and leoData.Story.Memories.ElFestival ~= nil, "Cinemática, foto del festival y recuerdo")
leo.Skip = {}

print("\n▶ Misión 11 «El proyecto final» (equipo, investigar, desastre, presentación)")
leo.Prefer = { "Un museo del colegio", "Presento delante", "Juntar las dos ideas", "Llamar al equipo" }
leo.Picks = { Companero = "Sara" }
leoData.Life.StageSeconds = 0.83 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Cole11_Proyecto ~= nil
end), "Misión 11 completa")
check(said(leo, "Ideas que no le he contado a nadie") and leoData.Story.Choices.Tema.V == "Museo" and leoData.Story.Choices.Rol.V == "Presentador", "Con Sara: el museo del colegio (solo si abriste la sala cerrada) y presentas tú")
check(said(leo, "Te puedo prestar la foto de mi clase") and said(leo, "Estamos empezando a enfadarnos."), "Investigas (Abu fue a tu colegio) y el equipo discute")
check(leoData.Story.Choices.Discusion.V == "Juntar" and leoData.Story.Flags.ArregloEnEquipo and said(leo, "Y lleva una tirita de cartón."), "Juntáis ideas y arregláis la maqueta rota en equipo")
local projectExtra = nil
for _, call in classCalls do
	if call.Player == leo and call.Subject == "Ciencias" and call.Mode == "Examen" then
		projectExtra = call.Extra
	end
end
check(projectExtra == 5, "La maqueta bonita da 5 segundos más por pregunta del jurado")
check(leoData.Story.Flags.ProyectoPremiado and leoData.Items.Maqueta == 1 and leoData.Story.Memories.ProyectoFinal ~= nil, "Sobresaliente: proyecto premiado, maqueta y recuerdo")
passTime(leo, 3700)
check(leoData.Story.Active.Eco_Periodico ~= nil and playQuest(leo, "Eco_Periodico") and said(leo, "abrirá el museo"), "Una hora después, tu proyecto sale en el periódico")

print("\n▶ Misión 12 «El último día» (recuerdos reales, cápsula, despedidas, instituto)")
check(leoData.Life.AgeYears >= 8 and received(leo, "Moment", "MOMENT.CUMPLEANOS"), "El tiempo jugado hace crecer: ya tiene 8 años o más")
leo.Prefer = { "¿empezamos de cero?", "seguimos juntos" }
leo.Picks = {}
leoData.Life.StageSeconds = 0.95 * HOURS.Nino * 3600
check(playUntil(leo, function()
	return leoData.Life.Stage == "Adolescente"
end), "Misión 12 completa: fin de primaria")
check(said(leo, "✨ Te sentaste junto a Sara") and said(leo, "Medalla de plata… y Abu"), "Los recuerdos son los de tu partida (el asiento del primer día, la plata del torneo)")
check(said(leo, "✨ Aquel examen que casi suspendes") and not said(leo, "✨ Estudiaste con Sara"), "Solo aparecen los recuerdos que viviste")
check(scene(leo, "Cole12_Capsula") and leoData.Story.Choices.Capsula.V == "Pregunta", "Se abre la cápsula: tu pregunta de la misión 09 (escena Cole12_Capsula)")
check(said(leo, "Y gracias por guardar mi secreto.") and said(leo, "Todavía me acuerdo de cuando me acusaste."), "Lucía y Bruno se despiden según vuestra historia")
check(leoData.Story.Choices.AdiosBruno.V == "DeCero" and leoData.Story.Choices.Promesa.V == "Juntos", "Empezar de cero con Bruno y la promesa del grupo")
check(leoData.Items.DiplomaPrimaria == 1 and leoData.Items.Llavero13 == 1 and leoData.Story.Memories.UltimoDiaCole ~= nil, "Diploma, llavero de Ramón y recuerdo del último día")
for _, questId in { "Cole01_PrimerDia", "Cole02_Mochila", "Cole03_Grupo", "Cole04_Malotes", "Cole05_Venganza", "Cole06_Examen", "Nino_Recados", "Cole07_Excursion", "Cole08_Torneo", "Cole09_Misterio", "Cole10_Festival", "Cole11_Proyecto", "Cole12_UltimoDia" } do
	check(leoData.Story.Completed[questId] ~= nil, "  hecha: " .. questId)
end
check(received(leo, "Moment", "MOMENT.DIA_COLE"), "Los días de cole terminados quedan como momentos")
check(scene(leo, "Cole12_FotoClase") and scene(leo, "Cole12_Despedida") and scene(leo, "Cole12_FinDeEpisodio") and cinematic(leo, "Nino_AInstituto"), "Escenas: la última foto, la despedida, el final de episodio y el paso al instituto")
task.wait(0.8)
check(leoData.Life.AgeYears == 13 and leoData.Story.Active.Ins01_NuevoInstituto ~= nil, "Con 13 años empieza el instituto")
leoData.Life.StageSeconds = 0

print("\n▶ Instituto 01 «El nuevo instituto» (parada, veterano, Bruno, Leire)")
leo.Prefer = { "Puedo ir por mi cuenta", "Das una vuelta", "¿Me enseñas qué fotos" }
leo.Picks = { Veterano = "Creer", SitioInstituto = "Bruno" }
check(playUntil(leo, function()
	return leoData.Story.Completed.Ins01_NuevoInstituto ~= nil
end), "Instituto 01 completa")
check(said(leo, "Pero en el recreo sí. ¡Lo prometimos!"), "Tus amigos recuerdan la promesa del último día")
check(leoData.Story.Choices.Veterano.V == "Creer" and said(leo, "¡Todos los años alguien cae!"), "Caes en la broma del «ascensor de alumnos»")
check(said(leo, "Yo también estoy en 1.º C"), "Iker (que se unió al grupo en la misión 05) está en tu clase")
check(said(leo, "Aquí hay sitio. Si quieres. De cero") and leoData.Story.Choices.SitioInstituto.V == "Bruno", "Bruno te ofrece sitio (te despediste con «empezamos de cero») y te sientas con él")
check(said(leo, "Leire comiendo sola") and leoData.Story.Flags.ConocesALeire and said(leo, "Esta es mi antigua calle"), "En el recreo encuentras a Leire sola y te acercas")
check(leoData.Items.CarnetInstituto == 1 and leoData.Story.Memories.PrimerDiaInstituto ~= nil, "Carnet del instituto y recuerdo del primer día")
passTime(leo, 2 * 3600 + 100)
check(leoData.Story.Active.Eco_Leire ~= nil and leoData.Story.Active.Eco_LeireSola == nil and playQuest(leo, "Eco_Leire"), "Dos horas después, Leire te busca")
check(leoData.Items.FotoDeLeire == 1, "Te regala una foto del primer día")

print("\n▶ Instituto 02 «Los clubes» (feria, periódico, murales, el sábado)")
leo.Prefer = { "Convencerla para pedir permiso", "Intentar las dos cosas" }
leo.Picks = { Club = "Periodico" }
leoData.Life.StageSeconds = 0.13 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Ins02_Clubes ~= nil
end), "Instituto 02 completa")
check(said(leo, "Tu primer caso: los murales") and said(leo, "Hay purpurina pegada en la pintura") and said(leo, "Soy yo. Lo hago porque el patio era gris"), "Periódico: investigas los murales y descubres a Vega")
check(leoData.Story.Choices.Reportaje.V == "Permiso" and said(leo, "«Una alumna pinta el instituto»"), "Convences a Vega para pedir permiso")
check(leoData.Story.Choices.Sabado.V == "Ambas" and said(leo, "Sale el primer número de «La Voz del Campus»") and said(leo, "¡Justo a tiempo para la tarta!"), "Llegas al evento del club y al cumpleaños de Nico")
check(leoData.Items.InsigniaClub == 1 and leoData.Story.Memories.PrimerClub ~= nil, "Insignia del club y recuerdo")

print("\n▶ Instituto 03 «¿Qué quieres ser?» (ocho profesiones, tu sueño, orientación)")
leo.Prefer = { "Sí. Me lo imagino", "Añadir triángulos", "Tengo más dudas" }
leo.Picks = {}
leoData.Life.StageSeconds = 0.26 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Ins03_QueQuieresSer ~= nil
end), "Instituto 03 completa")
local visitas = 0
for _, flag in { "Interes_Medicina", "Interes_Ingenieria", "Interes_Derecho", "Interes_Economia", "Interes_Oficio", "Interes_Cocina", "Interes_Deporte", "Interes_Audiovisual" } do
	if leoData.Story.Flags[flag] then
		visitas += 1
	end
end
check(visitas == 4 and leoData.Story.Flags.Interes_Ingenieria, "Visitas cuatro profesiones y marcas lo que te interesa")
check(said(leo, "querías «inventar cosas que no existen»") and not said(leo, "dijiste que querías salvar vidas"), "Tu sueño de la infancia (inventar) aparece en el laboratorio, y no en el hospital")
check(said(leo, "Aguanta dos kilos y medio") and said(leo, "Sofía me ha dicho que tus puentes"), "El puente del laboratorio y Carmen lo comenta")
check(leoData.Story.Choices.Orientacion.V == "Dudas" and leoData.Items.CuadernoProfesiones == 1 and leoData.Story.Memories.QueQuieresSer ~= nil, "Sales con dudas (y es bueno), cuaderno y recuerdo")

print("\n▶ La pandilla 1 «Las malas compañías» (camino del bien: frenar a Nerea)")
leo.Prefer = {}
leo.Picks = { Pellas = "Nerea" }
leoData.Life.StageSeconds = 0.31 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Pan1_MalasCompanias ~= nil
end), "La pandilla 1 completa")
check(said(leo, "No eres como los demás pringados") and said(leo, "Nadie mira mis dibujos"), "Rayo te invita a hacer pellas; convences a Nerea de que no vaya")
check(leoData.Story.Flags.AmigaNerea and leoData.Story.Flags.RechazasteLaPandilla and not leoData.Story.Flags.HicistePellas, "Rechazas la pandilla")
check(leo:GetAttribute("Camino") == "Responsable" and said(leo, "Hiciste bien en volver"), "Tu reputación: persona responsable (y Bruno, que ya fue «el malo», te lo dice)")

print("\n▶ La pandilla 2 «La noche del supermercado» (intentas frenarles)")
leo.Prefer = { "No lo hagáis" }
leoData.Life.StageSeconds = 0.37 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Pan2_LaNoche ~= nil
end), "La pandilla 2 completa")
check(leoData.Story.Choices.Plan.V == "Frenar" and said(leo, "Esta vez me quedo en casa") and not leoData.Story.Flags.Hurto, "Intentas frenarles: Nerea se queda en casa")
check(said(leo, "Gracias por lo de esta tarde") and said(leo, "Rayo… Rayo no está bien"), "A Rayo le pillan; Nerea te cuenta que en su casa no hay nadie")

print("\n▶ Instituto 04 «El primer empleo» (perfil, ofertas, entrevista, jornada, sueldo)")
leo.Prefer = { "Una cámara, como la de Leire", "Soy responsable", "No, pero aprendo rápido", "Le pido perdón", "Lo cuentas tal cual", "Una parte para ti" }
leo.Picks = { Empleo = "Barista" }
leoData.Life.StageSeconds = 0.45 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Ins04_PrimerEmpleo ~= nil
end), "Instituto 04 completa")
check(leoData.Story.Choices.Meta.V == "Camara" and said(leo, "Tu club también cuenta"), "Quieres una cámara; Carmen te ayuda con el perfil (tu club cuenta)")
check(leoData.Story.Choices.Empleo.V == "Barista" and said(leo, "Siéntate. Entrevista rápida") and not leoData.Story.Flags.MentisteEntrevista, "Entrevista con Lola diciendo la verdad")
check(said(leo, "¡Puntual! Así me gusta") and said(leo, "Y el cliente de la mesa es… Bruno"), "Llegas puntual y en mitad del turno se te cae la bandeja delante de Bruno")
check(leoData.Story.Flags.BuenTrabajo and leoData.Story.Choices.Sueldo.V == "Mitad", "Lo cuentas y lo arreglas; guardas la mitad del sueldo")
check(leoData.Items.PrimerSobre == 1 and leoData.Story.Memories.PrimerSueldo ~= nil, "Sobre del primer sueldo y recuerdo")
passTime(leo, 3 * 3600 + 100)
check(leoData.Story.Active.Eco_Carta ~= nil and playQuest(leo, "Eco_Carta") and said(leo, "Firma: Lola") and leoData.Items.CartaRecomendacion == 1, "Tres horas después, carta de recomendación de Lola (no mentiste)")

print("\n▶ La pandilla 3 «El cruce de caminos» (salvar a Rayo)")
leo.Prefer = { "Porque eres mi amigo" }
leo.Picks = { Camino = "Salvar" }
leoData.Life.StageSeconds = 0.53 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Pan3_Cruce ~= nil
end), "La pandilla 3 completa")
check(said(leo, "Cincuenta pavos por tarde") and said(leo, "Me voy de la pandilla"), "Rayo te ofrece el negocio de camisetas falsas; Nerea quiere salir")
check(said(leo, "Que venga mañana a las ocho") and said(leo, "Eres la única persona que no me ha dejado tirado") and leoData.Story.Flags.RayoCambia, "Consigues que Tomás le dé una oportunidad a Rayo en su taller")
check(leoData.Story.Flags.Camino_Trabajador and not leoData.Story.Flags.Camino_Delincuente and said(leo, "Nunca te dejaste arrastrar"), "Tu camino: el de una persona trabajadora (y nunca te dejaste arrastrar)")
leo.Picks = {}

print("\n▶ Instituto 05 «El rumor» (la foto de Omar, investigar, Nico, Darío)")
leo.Prefer = { "Escribes en el grupo", "Te creo. Pero ayúdame", "Te lo llevas aparte", "Bórrala y pídele perdón", "Borré la foto del grupo" }
leo.Picks = {}
leoData.Life.StageSeconds = 0.63 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Ins05_ElRumor ~= nil
end), "Instituto 05 completa")
check(leoData.Story.Choices.Foto.V == "Frenar" and said(leo, "La foto deja de moverse"), "Plantas cara en el grupo de clase y la foto deja de circular")
check(said(leo, "es Nico.") and leoData.Story.Choices.Bruno.V == "Confiar" and said(leo, "Darío Ruiz. D. R."), "Pistas: la compartió Nico; confías en Bruno y te dice quién la hizo")
check(leoData.Story.Choices.HablasNico.V == "Privado" and said(leo, "Quería que se rieran conmigo"), "Hablas con Nico aparte")
check(leoData.Story.Choices.Dario.V == "Perdon" and said(leo, "La he borrado. Fue una idiotez."), "Darío borra la foto y pide perdón")
check(said(leo, "¿Fuiste tú? Leire me dijo") and said(leo, "He hecho pulseras para todos"), "Consuelas a Omar en el banco y vuelve a clase")
check(leoData.Items.PulseraGrupo == 1 and leoData.Story.Memories.ElRumor ~= nil, "Pulsera del grupo y recuerdo")
passTime(leo, 3 * 3600 + 100)
check(leoData.Story.Active.Eco_Nico ~= nil and playQuest(leo, "Eco_Nico") and said(leo, "Me hiciste pensar sin hacerme quedar mal"), "Tres horas después, Nico te da las gracias")

print("\n▶ Instituto 06 «La gran decisión» (planes, Carmen, selectividad, elegir, graduación)")
leo.Prefer = {}
leo.Picks = { Estudios = "Ingenieria" }
leoData.Life.StageSeconds = 0.91 * HOURS.Adolescente * 3600
check(playUntil(leo, function()
	return leoData.Life.Stage == "AdultoJoven"
end), "Instituto terminado")
check(said(leo, "Lola me ha dicho que si termino") and said(leo, "Por decírmelo a la cara, aparte."), "Los planes de tus amigos (Nico se acuerda del rumor)")
check(said(leo, "Sofía todavía habla de tu puente") and said(leo, "Y tu primer trabajo de verano"), "Carmen repasa tus intereses y tu primer trabajo")
check(said(leo, "¡La persona de los triángulos!"), "En la jornada de puertas abiertas, Sofía te reconoce")
local selectividadExtra = nil
for _, call in classCalls do
	if call.Player == leo and call.Subject == "Tecnologia" and call.Mode == "Examen" then
		selectividadExtra = call.Extra
	end
end
check(selectividadExtra == 5, "Estudiar da 5 segundos más por pregunta en la selectividad")
check(leoData.Story.Flags.Acceso8 and leoData.Story.Flags.Acceso5, "Con un 8 en selectividad, puede entrar en cualquier carrera (nota de corte)")
check(leoData.Story.Choices.Futuro and leoData.Story.Choices.Futuro.V == "Universidad" and leoData.Story.Flags.VaALaUniversidad and said(leo, "a vivir en la residencia del campus"), "Elige ir a la universidad (vivirá en la residencia)")
check(said(leo, "Algunos esperasteis un ascensor") and leoData.Items.OrlaInstituto == 1 and leoData.Story.Memories.LaGranDecision ~= nil, "Graduación del instituto: orla y recuerdo")
check(cinematic(leo, "Adol_Selectividad"), "Cinemática de selectividad")
task.wait(0.8)
check(leoData.Story.Active.Uni01_PrimerDia ~= nil and cinematic(leo, "Uni_PrimerDia"), "Empieza la universidad con su cinemática")

local function lastExtra(subject: string, mode: string): number?
	local extra = nil
	for _, call in classCalls do
		if call.Player == leo and call.Subject == subject and call.Mode == mode then
			extra = call.Extra
		end
	end
	return extra
end

print("\n▶ Universidad 01 «Primer día en el campus» (el reloj, Luca, tu facultad, Beltrán)")
leo.Prefer = { "Lo voy a cuidar" }
leo.Picks = { ComidaUni = "Luca", Estudios = "Ingenieria" }
leoData.Life.StageSeconds = 0
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni01_PrimerDia ~= nil
end), "Universidad 01 completa")
check(said(leo, "te da un reloj viejo") and leoData.Items.RelojAbu == 1, "{abu} te regala su reloj")
check(leoData.Story.Choices.Estudios and leoData.Story.Choices.Estudios.V == "Ingenieria", "Elige Ingeniería el primer día, en la matrícula (su nota se lo permite)")
check(said(leo, "Dos camas más, todavía vacías"), "Su primera noche es en la residencia de estudiantes")

print("\n▶ Universidad · La residencia (compañeros de cuarto, la compra, la nevera, la primera cena)")
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni01b_Residencia ~= nil
end), "La residencia completa")
check(said(leo, "Son sagradas") and leoData.Items.LlaveResidencia == 1 and leoData.Story.Choices.Normas ~= nil, "Iván y Candela (de su clase), las normas de la nevera y la llave de la 214")
check(said(leo, "Facultad de Ingeniería. Física el primer día") and table.find(classesOf(leo), "Fisica") ~= nil, "El horario y la clase son los de tu carrera (Ingeniería)")
check(said(leo, "Otra vez juntos."), "Mateo (tu primer amigo) estudia Ingeniería contigo")
check(said(leo, "me ha dado croquetas gratis") and said(leo, "Por eso me hice voluntario"), "Descubres el campus y comes con Luca")
check(said(leo, "Me llaman «el nuevo»") and leoData.Items.CarnetUniversitario == 1 and leoData.Story.Memories.PrimerDiaUni ~= nil, "Por la noche, el grupo de siempre por mensajes; carnet y recuerdo")

print("\n▶ Universidad 02 «El proyecto» (un grupo con personalidades)")
leo.Prefer = { "No tienes que cargar", "Coordinar no es mandar", "Hacemos las reuniones por la mañana", "¿Y si haces la música", "Cada uno en lo que se le da bien" }
leo.Picks = {
	Gestion = function()
		return if said(leo, "En la vida no se eligen los compañeros") then "Hablar" else "Cambiar" -- primero pide cambiarse
	end,
}
leoData.Life.StageSeconds = 0.19 * HOURS.AdultoJoven * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni02_ElProyecto ~= nil
end), "Universidad 02 completa")
check(said(leo, "diseñar un puente peatonal"), "El proyecto es de tu carrera")
check(said(leo, "En la vida no se eligen los compañeros") and leoData.Story.Choices.Gestion.V == "Hablar", "Pedir cambiar de grupo no se puede; decides hablar con cada uno")
check(said(leo, "Tengo una beca") and said(leo, "Es mi hermano") and said(leo, "Lo mío es esto"), "Descubres qué le pasa a cada uno")
check(leoData.Story.Flags.EquipoUnido and lastExtra("Calculo", "Examen") == 5, "Equipo unido: 5 segundos más en la presentación")
check(said(leo, "Se nota un equipo detrás") and leoData.Items.FotoEquipoUni == 1 and leoData.Story.Memories.ElProyectoUni ~= nil, "Sobresaliente, foto del grupo cuatro y recuerdo")
passTime(leo, 3 * 3600 + 100)
check(leoData.Story.Active.Eco_Concierto ~= nil and playQuest(leo, "Eco_Concierto") and said(leo, "Voy a terminar la carrera"), "Tres horas después, el concierto de Pablo")

print("\n▶ Universidad 03 «El primer trabajo» (perfil, ofertas, Alba, decir que no)")
leo.Prefer = { "Las fracciones con dinosaurios", "Decir que no, con educación" }
leo.Picks = { TrabajoUni = "Clases" }
leoData.Life.StageSeconds = 0.37 * HOURS.AdultoJoven * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni03_PrimerTrabajo ~= nil
end), "Universidad 03 completa")
check(said(leo, "Valía oro, sí."), "La carta de recomendación del instituto sirve en tu perfil")
check(leoData.Story.Choices.TrabajoUni.V == "Clases" and said(leo, "¡UN SIETE!"), "Clases particulares: Alba aprueba fracciones con dinosaurios")
check(not leoData.Story.Flags.CubristeTurno and lastExtra("Fisica", "Examen") == 5, "Dices que no a tiempo y llegas al examen con repaso (5 s más)")
check(leoData.Items.ContratoTrabajo == 1 and leoData.Story.Memories.PrimerTrabajoUni ~= nil and said(leo, "Te he hecho un dibujo"), "Contrato, recuerdo y el dibujo de Alba")

print("\n▶ Universidad 04 «Las prácticas» (según tu carrera, el error del informe)")
leo.Prefer = { "Decírselo a tu tutor" }
leo.Picks = {}
leoData.Life.StageSeconds = 0.56 * HOURS.AdultoJoven * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni04_Practicas ~= nil
end), "Universidad 04 completa")
check(said(leo, "¡La persona de los triángulos! Ahora trabajo para TecnoVal"), "Sofía, la de la semana de las profesiones, es tu tutora de Ingeniería")
check(said(leo, "Amortiguadores de masa") and not said(leo, "Sesenta años, fumador"), "El caso es de tu carrera (la pasarela del río), no de otra")
check(leoData.Story.Choices.ErrorInforme.V == "Decir" and said(leo, "Así se construyen puentes que no se caen") and lastExtra("PracticaIngenieria", "Practica") == 4, "Confiesas tu error: la tutora lo valora (y tienes 4 s más)")
check(leoData.Story.Flags.OfertaTrabajo and leoData.Items.InformePracticas == 1 and leoData.Story.Memories.Practicas ~= nil, "Oferta de trabajo para cuando termines, informe y recuerdo")

print("\n▶ Universidad 05 «Tu primer piso» (independizarte, la mudanza, {abu})")
leo.Prefer = { "Me da un poco de miedo", "Habláis y hacéis un reparto justo" }
leo.Picks = { CompiPiso = "Luca" }
leoData.Life.StageSeconds = 0.73 * HOURS.AdultoJoven * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni05_PrimerPiso ~= nil
end), "Universidad 05 completa")
check(said(leo, "Aquí tienes siempre tu cuarto") and said(leo, "el pacto italiano"), "Te da miedo irte de casa; vives con Luca")
check(said(leo, "una carta de tu familia") and said(leo, "Yo cocino para dos") and leoData.Story.Choices.Convivencia.V == "Hablar", "La caja de los recuerdos y un reparto justo en casa")
check(said(leo, "Traigo una planta") and leoData.Story.Flags.TieneHogar and leoData.Items.LlavesPiso == 1 and leoData.Story.Memories.PrimerPiso ~= nil, "{abu} viene de visita; ya tienes casa propia")

print("\n▶ Universidad 06 «La graduación» (ceremonia, foto, el brindis de toda una vida)")
leo.Prefer = { "La sudadera de dinosaurios" }
leo.Picks = {}
leoData.Life.StageSeconds = HOURS.AdultoJoven * 3600
check(playUntil(leo, function()
	return leoData.Story.Completed.Uni06_Graduacion ~= nil
end), "Universidad 06 completa")
check(leoData.Story.Choices.LookGraduacion.V == "Dinosaurios" and said(leo, "Tienes trabajo esperando"), "La sudadera de dinosaurios bajo la toga, y la oferta de las prácticas")
check(said(leo, "Todo empezó ahí.") and said(leo, "La final del torneo. Plata.") and said(leo, "Nunca te lo agradecí bien"), "El brindis recuerda lo que viviste: Mateo, el torneo, Leire")
check(said(leo, "que empezamos de cero") and not said(leo, "Ya ni me acuerdo de por qué"), "Bruno recuerda que empezasteis de cero")
local degreeSubjects = Subjects.Degrees.Ingenieria
local uniClasses = {}
for _, subject in classesOf(leo) do
	uniClasses[subject] = true
end
check(uniClasses[degreeSubjects.Asignatura1] and uniClasses[degreeSubjects.Asignatura2], "Las clases son las de Ingeniería")
check(uniClasses[degreeSubjects.Fisico], "Y las pruebas físicas también son de Ingeniería (la visita de obra)")
local exams = leoData.Story.Completed
check(exams.UniEx1_Enero and exams.UniEx2_Junio and exams.UniEx3_Parcial and exams.UniEx4_TFG, "El ciclo real de la carrera: enero, junio, el parcial imposible y el TFG")
check(leoData.Story.Flags.EneroAprobado and leoData.Story.Flags.JunioAprobado and leoData.Items.TFG == 1 and said(leo, "Ensayas cinco veces"), "Aprueba sus exámenes, ensaya con sus compañeros y defiende el TFG")
local circuits = 0
for _, call in classCalls do
	if call.Player == leo and call.Mode == "Circuito" and call.Subject == "FisicoIngenieria" then
		circuits += 1
	end
end
check(circuits == 4, "Cuatro pruebas físicas a lo largo de la carrera")
check(leoData.Story.Flags.Graduado and leoData.Education.Degrees[degreeSubjects.Titulo] ~= nil, "Título guardado: graduado en Ingeniería")
check(cinematic(leo, "Uni_Graduacion") and leoData.Items.OrlaUniversidad == 1 and leoData.Story.Memories.Graduacion ~= nil, "Cinemática de graduación, orla y recuerdo")
task.wait(1)
check(leoData.Story.Chapter == "Adulto_VolarDelNido" and leoData.Story.Active.Adu01_PrimerContrato ~= nil, "Después empieza la vida adulta: «Volar del nido»")

print("\n▶ Vida adulta 01 «Mi primer contrato» (trabajo de tu carrera, facturas)")
leo.Prefer = { "Pido consejo", "Hacer un presupuesto" }
leo.Picks = {}
check(playUntil(leo, function()
	return leoData.Story.Completed.Adu01_PrimerContrato ~= nil
end), "Vida adulta 01 completa (sin volver a pedir casa: ya tienes la tuya)")
check(said(leo, "¡Por fin! En TecnoVal nadie se ha olvidado") and leoData.Story.Choices.PrimerCaso.V == "Consejo", "Te contratan donde hiciste las prácticas (confesaste tu error) y pides consejo")
check(leoData.Story.Choices.Facturas.V == "Presupuesto" and said(leo, "La persona de los números") and not leoData.Story.Flags.FacturaPendiente, "Primeras facturas: presupuesto con Ignacio")
check(leoData.Items.PrimeraNomina == 1 and leoData.Story.Memories.PrimerContrato ~= nil and said(leo, "no está muy bien"), "Primera nómina, recuerdo… y una llamada sobre {abu}")

print("\n▶ Vida adulta 02 «Un atardecer junto al mar» (el hospital, el carnet, la playa)")
leo.Prefer = { "Le coges la mano", "Haré cosas bonitas" }
leo.Picks = { ViajeAbu = "Coche" }
check(playUntil(leo, function()
	return leoData.Story.Completed.Adu02_Atardecer ~= nil
end), "Vida adulta 02 completa")
check(said(leo, "Me gustaría verlo otra vez. Contigo.") and said(leo, "¿Llevas el reloj? …Lo llevas."), "{abu} en el hospital: quiere ver el mar contigo (y te pregunta por su reloj)")
check(said(leo, "Toma las llaves del coche viejo"), "Te sacas el carnet de coche y tu familia te presta el coche")
check(said(leo, "Y de tu graduación.") and leoData.Story.Choices.PromesaAbu.V == "CosasBonitas", "En la playa, {abu} recuerda tu vida y le haces una promesa")
check(cinematic(leo, "Adu02_Atardecer") and leoData.Items.ConchaAbu == 1 and leoData.Story.Memories.AtardecerConAbu ~= nil, "El atardecer: cinemática, la concha y el recuerdo")

print("\n▶ Vida adulta 03 «El reencuentro» (la cafetería de Omar, Lucía, el banco del parque)")
leo.Prefer = { "¿Puedo venir a contarle", "Nada de promesas" }
leo.Picks = {}
check(playUntil(leo, function()
	return leoData.Story.Completed.Adu03_Reencuentro ~= nil
end), "Vida adulta 03 completa")
check(said(leo, "Firmé el mes pasado") and said(leo, "Mycena sarae") and said(leo, "Pues esto es el diez."), "Invitas al grupo: Nico futbolista, Sara bióloga, Bruno policía (empezasteis de cero)")
check(said(leo, "y que ahora las diseñas en TecnoVal") and leoData.Story.Flags.CharlaColegio, "Le cuentas a Lucía que cumpliste tu sueño de niño (inventar cosas)")
check(said(leo, "Perfecta según mis estándares") and said(leo, "Y aquí estamos. Con trabajos"), "La tortilla perfecta y la promesa del último día de colegio, cumplida")
check(leoData.Story.Choices.PromesaAdulta.V == "Siempre" and cinematic(leo, "Adu03_Foto") and leoData.Items.FotoReencuentro == 1 and leoData.Story.Memories.ElReencuentro ~= nil, "Promesa nueva, foto y recuerdo")
task.wait(1)
check(leoData.Story.Chapters.Adulto_VolarDelNido ~= nil and leoData.Story.Chapters.Adulto_NuevaVida == nil, "Capítulo «Volar del nido» terminado (el de los veteranos no se repite)")
check(cinematic(leo, "Montaje_Joven_Adulto") and leoData.Life.Stage == "Adulto" and cinematic(leo, "Nido_Fin") and cinematic(leo, "TuVida_Entrada"), "Montaje adulto joven → adulto, final del capítulo y cabecera de «Tu vida»")
passTime(leo, 13 * 3600)
-- (las consecuencias llegan de una en una: antes que Rayo puede llegar el ascenso de Adu_Ascenso)
for _ = 1, 4 do
	if leoData.Story.Active.Eco_RayoAdulto or leoData.Story.Completed.Eco_RayoAdulto then
		break
	end
	passTime(leo, 0)
end
check(leoData.Story.Active.Adu_Ascenso ~= nil, "Meses después, tu jefa quiere verte: un ascenso (Adu_Ascenso)")
check(leoData.Story.Active.Eco_RayoAdulto ~= nil and playQuest(leo, "Eco_RayoAdulto") and said(leo, "«Taller Rayo». Mío."), "Años después, Rayo tiene su propio taller gracias a ti")
check(pcall(serde.encode, "json", leoData), "Toda una vida se puede guardar (JSON válido)")

print("\n▶ Otra rama: dejar de estudiar y ponerse a trabajar")
local eva = newPlayer("Eva", "Adolescente")
local evaData = profiles[eva]
eva.Picks = { Camino = "Negocio" } -- en el cruce de caminos, elige el mal camino
task.wait(0.3)
evaData.Life.StageSeconds = HOURS.Adolescente * 3600
check(playUntil(eva, function()
	return evaData.Life.Stage == "AdultoJoven"
end, "Trabajar"), "Instituto terminado")
task.wait(1)
check(evaData.Story.Flags.EmpiezaATrabajar and not evaData.Story.Flags.VaALaUniversidad, "Elige trabajar")
check(evaData.Story.Active.Uni01_PrimerDia == nil and evaData.Story.Active.Adu01_PrimerContrato ~= nil, "No va a la universidad: empieza directamente la vida adulta")
check(playUntil(eva, function()
	return evaData.Story.Completed.Adu01_PrimerContrato ~= nil
end), "Sin carrera: busca casa y su jefe del primer verano le hace encargado o encargada")
check(said(eva, "Encargad") and said(eva, "¿Te atreves?") and evaData.Story.Flags.TieneHogar, "Lola le ofrece llevar la cafetería; ya tiene casa propia")

print("\n▶ El mal camino: pellas, pintada, el súper, las camisetas falsas… y las consecuencias")
check(evaData.Story.Flags.HicistePellas and evaData.Story.Flags.Pintada and evaData.Story.Flags.MentisteFamilia, "Hace pellas, pinta el muro y miente en casa")
check(evaData.Story.Flags.Hurto and evaData.Story.Flags.Escapaste and said(eva, "No sabe a nada."), "Roba en el súper de Paco y escapa")
check(evaData.Story.Flags.Camino_Delincuente and said(eva, "Son de MI equipo. ¿En serio?") and (evaData.Story.Traits.Rebeldia or 0) >= 6, "Entra en el negocio de camisetas falsas; Nico le ve (Rebeldía alta)")
check(eva:GetAttribute("Camino") == "Delincuente", "Su reputación: el mal camino")
eva.Prefer = { "Fui yo", "Lo dejo. Todo", "Colaboro" }
eva.Picks = { UltimoTrabajo = "Aceptar" }
passTime(eva, 3 * 3600 + 100)
-- Hay varias consecuencias pendientes a la vez: el juego las empieza de una en una
for _ = 1, 8 do
	if evaData.Story.Active.Eco_Camaras and evaData.Story.Active.Eco_Redada then
		break
	end
	passTime(eva, 60)
end
local ecoCamaras = evaData.Story.Active.Eco_Camaras ~= nil and playQuest(eva, "Eco_Camaras")
local ecoRedada = evaData.Story.Active.Eco_Redada ~= nil and playQuest(eva, "Eco_Redada")
check(ecoCamaras and evaData.Story.Flags.AvisoPolicia and evaData.Story.Flags.PerdonPaco, "Las cámaras la grabaron: la policía en la puerta, servicio a la comunidad y perdón a Paco")
check(ecoRedada and evaData.Story.Flags.Antecedentes, "La redada de las camisetas: queda en su expediente")
passTime(eva, 13 * 3600)
for _ = 1, 8 do
	if evaData.Story.Active.Eco_RayoAdulto then
		break
	end
	passTime(eva, 60)
end
check(evaData.Story.Active.Eco_RayoAdulto ~= nil and playQuest(eva, "Eco_RayoAdulto"), "Ya de adulta, Rayo vuelve con «un último trabajo»")
check(said(eva, "Doscientos por un viaje") and said(eva, "Cajas sin papeles"), "Acepta y en el control está… Bruno, ahora policía")
check(evaData.Story.Flags.Detenido and evaData.Story.Flags.Redimido and not evaData.Story.Flags.Camino_Delincuente and eva:GetAttribute("Camino") == "Responsable", "Detenida, colabora y cambia de camino: nunca es tarde")

---------------------------------------------------------------------
-- Misiones locas (secundarias de cada etapa, con Cosme)
---------------------------------------------------------------------
local QuestsData = loadModule(ROOT .. "/shared/LifeStory/Quests")

-- Ir al sitio, esperar a que te la ofrezcan, aceptarla y jugarla entera
local function playLoco(player, questId: string): boolean
	local quest = QuestsData[questId]
	local story = profiles[player].Story
	story.Declined[questId] = nil -- si se rechazó mientras se jugaba otra, ahora sí
	for _ = 1, 12 do
		if story.Active[questId] or story.Completed[questId] then
			break
		end
		player.At = quest.Offer.Place
		passTime(player, 5)
		if received(player, "Offer", quest.Title) then
			fromClient(player, "Offer", questId, true)
		else
			-- En el mismo sitio te pueden ofrecer otra (en casa: los gnomos o tu yo malvado): esa, ahora no
			for _, message in player.Inbox do
				if message.Kind == "Offer" and message.Payload.QuestId ~= questId and not message.Answered then
					message.Answered = true
					fromClient(player, "Offer", message.Payload.QuestId, false)
				end
			end
		end
	end
	return story.Active[questId] ~= nil and playQuest(player, questId, 200)
end

print("\n▶ Misiones locas · Infancia (Cosme, el vecino del garaje)")
local ItemsDataEarly = loadModule(ROOT .. "/shared/Items")
local kiko = newPlayer("Kiko", "Nino")
local kikoData = profiles[kiko]
kiko.Prefer = { "¡Te ayudo", "Le cambias", "Será nuestro secreto", "Un título", "¡Ha sido lo mejor", "Los ha hecho un clon", "Contrátala" }
lighting.ClockTime = 17
check(playLoco(kiko, "Loco_N1_Cosme") and kikoData.Items.PistolaBurbujas == 1 and kikoData.Story.Flags.SecretoCosme, "El vecino del garaje: las 3 piezas, el bocadillo del martes pasado y la pistola de burbujas")
check(said(kiko, "Tenemos un problema."), "Bigotes, el gato del cole, habla (por el chip de la abuela de Cosme)")
local hitsBefore = kiko.Hits or 0
lighting.ClockTime = 12 -- Bigotes y los clones pasan en el cole: con el cole abierto
-- En el combate, las cucarachas son enemigos: sin cartel de «Interactuar» (se las ataca) y la nave en el patio
local roachSpecs, shipInFight = {}, false
local sceneMock = H.mocks[H.ROOT .. "/server/Services/SceneService"]
local realSet = sceneMock.set
sceneMock.set = function(player, questId, actors, props, ...)
	if player == kiko and questId == "Loco_N2_Bigotes" then
		for _, spec in actors do
			if string.sub(spec.Npc, 1, 9) == "Cucaracha" then
				roachSpecs[spec.Npc] = spec
				shipInFight = shipInFight or table.find(props, "Nave") ~= nil
			end
		end
	end
	return realSet(player, questId, actors, props, ...)
end
check(playLoco(kiko, "Loco_N2_Bigotes") and kikoData.Items.CoronaBigotes == 1 and kikoData.Story.Flags.DuqueDeGatonia, "Bigotes, emperador de Gatonia: tres cucarachas espaciales a globazos y un título de nobleza")
check((kiko.Hits or 0) - hitsBefore == 7, "Cada cucaracha aguanta sus globos (2 + 2 + 3)")
do
	local ok = roachSpecs ~= nil
	for _, npc in { "Cucaracha1", "Cucaracha2", "Cucaracha3" } do
		local spec = roachSpecs and roachSpecs[npc]
		ok = ok and spec ~= nil and spec.Enemy == true and spec.Prompt == false and spec.Mode == "Hunt"
	end
	check(ok, "En el combate las cucarachas son enemigos sin cartel de «Interactuar» (Enemy, Prompt = false): el botón es el de atacar")
	check(shipInFight == true, "La nave de las cucarachas está en el patio durante el combate")
	sceneMock.set = realSet
end
kiko.CaughtBy = "PolloGigante"
-- El rayo encogedor: te lo dan al empezar el combate (en tu barra), se usa desde la barra y se
-- devuelve al acabar (y luego te lo quedas de recuerdo)
local rayInFight, rayHits, loanedInFight, rayAfterRepeats = nil, nil, nil, nil
H.Service.observe(function(kind, who, questId, info)
	if who == kiko and questId == "Loco_N3_Pollo" and info and info.Type == "Fight" then
		if kind == "StepEnter" then
			task.defer(function()
				rayInFight = kikoData.Items.RayoEncogedor
				loanedInFight = kikoData.Story.Loans and kikoData.Story.Loans.RayoEncogedor
				-- Reaparecer / volver a entrar / cada vuelta del combate: nunca una segunda copia
				for _ = 1, 4 do
					H.Service.ensureLoans(kiko)
				end
				rayAfterRepeats = kikoData.Items.RayoEncogedor
				local before = kiko.Hits or 0
				H.Service.useWeapon(kiko, "RayoEncogedor")
				rayHits = (kiko.Hits or 0) - before
			end)
		end
	end
end)
check(playLoco(kiko, "Loco_N3_Pollo") and kikoData.Items.RayoEncogedor == 1, "La gallina de seis metros: huir hasta el silo y encogerla con el rayo")
check(said(kiko, "Te ha cogido con el pico") or kiko.CaughtBy == nil, "Si Petra te atrapa, vuelves al granero")
check((kiko.Catches or 0) >= 1 and kiko.CaughtWhere == "GranjaPatio", "La captura es la segura (SceneService.catch): te deja de pie en la puerta del granero")
check(rayInFight == 1 and loanedInFight == "Loco_N3_Pollo", "Al empezar el combate tienes el rayo encogedor en tu barra (prestado por Cosme)")
check(rayHits == 1, "Usarlo desde la barra dispara a Petra")
check(rayAfterRepeats == 1, "Dar el arma prestada es idempotente: aunque se compruebe muchas veces, solo hay un rayo")
check(kikoData.Story.Loans == nil, "Al acabar, el préstamo se devuelve (y el rayo se queda de recuerdo)")
check(playLoco(kiko, "Loco_N4_Clones") and kikoData.Items.FotoClones == 1 and said(kiko, "por aula es el máximo legal"), "Deberes clónicos: tres clones en el cole y la foto de los cuatro")
lighting.ClockTime = 23
check(playLoco(kiko, "Loco_N5_Perez") and kikoData.Items.MonedaPerez == 1 and kikoData.Story.Flags.RataContratada, "La huelga del Ratón Pérez: persecución nocturna y la moneda de 1702")
kiko.Prefer = { "¡Prometido! Solo a latas" }
check(QuestsData.Loco_N6_Tirachinas.Requires.Completed[1] == "Cole01_PrimerDia", "El tirachinas llega en cuanto empiezas el cole (tras «El primer día»)")
kikoData.Story.Completed.Cole01_PrimerDia = os.time()
lighting.ClockTime = 17
check(playLoco(kiko, "Loco_N6_Tirachinas") and kikoData.Items.Tirachinas == 1 and said(kiko, "Solo a latas"), "El tirachinas del campeón: el baúl de {abu}, práctica con latas y las palomas robot de Cosme")
check(ItemsDataEarly.get("Tirachinas").Kind == "Gadget" and ItemsDataEarly.get("Tirachinas").Effect == "Sling", "El tirachinas se usa desde la mochila: dispara bellotas en arco")
check(kikoData.Story.Memories.ConociCosme ~= nil and kikoData.Story.Memories.GallinaGigante ~= nil and kikoData.Story.Memories.RatonPerez ~= nil, "Los recuerdos de las misiones locas quedan en su vida")

print("\n▶ Saga de la Grieta · Acto I (misiones canónicas: siempre en el mapa)")
-- Escenas del motor (Happenings) que ha visto cada jugador: las de la Saga sustituyen a las cinemáticas
-- viejas en el mismo paso (Grieta_Coser, Grieta_Rota, Grieta_Fusion, Grieta_Final)
local seenScenes = {}
loadModule(ROOT .. "/server/Services/HappeningService").onFinished(function(player, id)
	seenScenes[player] = seenScenes[player] or {}
	seenScenes[player][id] = true
end)
local function scene(player, id: string): boolean
	return seenScenes[player] ~= nil and seenScenes[player][id] == true
end
local function canonIds(player)
	local raw = player:GetAttribute("CanonMarks") or "[]"
	local ids = {}
	for id in raw:gmatch('"Id":"([%w_]+)"') do
		ids[id] = true
	end
	return ids
end
local sol = newPlayer("Sol", "Nino")
local solData = profiles[sol]
sol.Prefer = { "¡Te ayudo", "Será nuestro secreto", "Te saco de aquí", "Por favor. Es para", "No. Es de Lucía", "¿Quién es Cósimo" }
lighting.ClockTime = 17
passTime(sol, 5)
check(canonIds(sol).Loco_N1_Cosme and not canonIds(sol).Saga_02_Grieta, "Al empezar, el mapa marca la primera misión canónica (y solo esa)")
check(playLoco(sol, "Loco_N1_Cosme") and solData.Story.Flags.GrietaVista, "1 · El vecino del garaje (canónica: empieza sola al llegar) y la raja de luz del cielo")
check(sol:GetAttribute("SkyRift") == "Rasguno", "La Grieta del cielo aparece (fase Rasguno: un rasguño de luz) tras conocer a Cosme")
sol.At = "Parque" -- lejos del garaje (si no, la siguiente empieza sola y ya no tiene marca)
passTime(sol, 5)
check(canonIds(sol).Saga_02_Grieta and not canonIds(sol).Loco_N1_Cosme, "Hecha una, su marca desaparece y aparece la siguiente")
check(playLoco(sol, "Saga_02_Grieta") and solData.Items.MonedaPerilla == 1 and said(sol, "¿Quién es Cósimo?"), "2 · La grieta en el cielo: la moneda con perilla y el nombre de Cósimo")
check(sol:GetAttribute("SkyRift") == "Crece", "Tras «La grieta en el cielo», la Grieta ha crecido (fase Crece)")
check(playLoco(sol, "Saga_03_Pez") and solData.Story.Flags.OyoAncla and said(sol, "He hablado de más"), "3 · El pez que sabía demasiado: el Consorcio y la palabra «Ancla»")
check(playLoco(sol, "Saga_04_Ventanilla") and solData.Items.SelloAduana == 1 and said(sol, "Alguien del otro lado tira de ella"), "4 · La ventanilla 42: burocracia del tiempo y un aviso de Cronos")
lighting.ClockTime = 21 -- «La noche de las cosas perdidas»: de noche
check(playLoco(sol, "Saga_05_Perdidas") and solData.Items.CalcetinSolitario == 1 and said(sol, "Hay cosas que perdemos"), "5 · La noche de las cosas perdidas: devolver lo perdido y el Monstruo de los Calcetines")
passTime(sol, 5)
check(canonIds(sol).Saga_06_Coser, "El final del acto está marcado en el mapa (aunque sea de día: pide la noche)")
lighting.ClockTime = 21
check(playLoco(sol, "Saga_06_Coser") and solData.Items.AgujaCuantica == 1 and solData.Story.Flags.SagaActo1 and said(sol, "Ya te he visto, Ancla"), "6 · Coser el cielo: los anclajes, los agentes grises y la voz de Cósimo")
check(scene(sol, "Grieta_Coser"), "Escena: la aguja cose el cielo (Grieta_Coser)")
check(sol:GetAttribute("SkyRift") == "Cosida", "Cosida: en el cielo queda solo una cicatriz (fase Cosida)")

print("\n▶ Saga de la Grieta · Actos II, III y IV (de la adolescencia a la vida adulta, hasta el final)")
local nora = newPlayer("Nora", "Adolescente")
local noraData = profiles[nora]
for _, id in { "Loco_N1_Cosme", "Saga_02_Grieta", "Saga_03_Pez", "Saga_04_Ventanilla", "Saga_05_Perdidas", "Saga_06_Coser" } do
	noraData.Story.Completed[id] = os.time()
end
noraData.Story.Flags.SagaActo1 = true
nora.Picks = { Trato = "No" }
local function sagaStage(stage: string)
	noraData.Life.Stage = stage
	nora:SetAttribute("LifeStage", stage)
end
lighting.ClockTime = 12
passTime(nora, 5)
check(canonIds(nora).Saga_07_Costuras, "Acto II: tras coser el cielo, el mapa marca la siguiente canónica")
check(playLoco(nora, "Saga_07_Costuras") and noraData.Items.CredencialAyudante == 1, "7 · Las costuras: ayudante oficial de Cosme")
check(playLoco(nora, "Saga_08_MegaVerso") and noraData.Items.FolletoMegaVerso == 1, "8 · MegaVerso S.A.: el Proyecto Fusión")
lighting.ClockTime = 22
check(playLoco(nora, "Saga_09_Archivo") and noraData.Items.CintaArchivo == 1, "9 · El archivo (de noche): eres el Ancla")
lighting.ClockTime = 20
check(playLoco(nora, "Saga_10_Fiesta"), "10 · La fiesta del fin del mundo")
lighting.ClockTime = 12
check(playLoco(nora, "Saga_11_Cronos") and noraData.Items.RelojArena == 1, "11 · Cronos se pasa a tu bando")
check(playLoco(nora, "Saga_12_Graduacion") and noraData.Story.Flags.SagaActo2 and noraData.Story.Flags.CosmeSecuestrado and scene(nora, "Grieta_Rota"), "12 · La graduación: la costura se rompe y Cósimo se lleva a Cosme (escena Grieta_Rota)")

sagaStage("AdultoJoven")
passTime(nora, 5)
check(canonIds(nora).Saga_13_SinCosme, "Acto III: en la universidad, el mapa marca el garaje cerrado")
check(playLoco(nora, "Saga_13_SinCosme") and noraData.Items.CuadernoCosme == 1 and noraData.Story.Flags.CompisSabenGrieta, "13 · Sin Cosme: el cuaderno y el equipo de rescate")
check(playLoco(nora, "Saga_14_Bigotes") and noraData.Items.CollarDiplomatico == 1 and noraData.Story.Flags.CoordenadasCosimo, "14 · Gatonia: huir de la policía gatuna y las coordenadas")
lighting.ClockTime = 23
check(playLoco(nora, "Saga_15_Reestreno") and noraData.Items.PaseVIP == 1, "15 · El reestreno del reality (de noche, en el monte)")
lighting.ClockTime = 12
check(playLoco(nora, "Saga_16_66B") and noraData.Items.MapaMalvado == 1 and noraData.Story.Flags.ConoceTuMalvado, "16 · La dimensión 66-B y tu yo malvado")
check(playLoco(nora, "Saga_17_Rescate") and noraData.Story.Flags.CosmeRescatado and not noraData.Story.Flags.CosmeSecuestrado, "17 · El rescate: desconectar la cápsula y huir de los drones")
check(playLoco(nora, "Saga_18_Precio") and noraData.Items.FotoSinMemoria == 1 and noraData.Story.Flags.SagaActo3, "18 · El precio: Cosme no recuerda nada")
check(said(nora, "¡Buenos días, Valmar!") and not said(nora, "{Saludo}"), "Los saludos van según la hora (a mediodía, Cósimo no dice «buenas noches»)")

sagaStage("Adulto")
nora.At = "Parque" -- se va del garaje (si no, la siguiente canónica empieza sola allí mismo)
passTime(nora, 5)
check(canonIds(nora).Saga_19_Recuerdos, "Acto IV: de adulto, el mapa marca devolverle la memoria a Cosme")
local deuda = QuestsData.Loco_D2_Deuda
local function offered(player, questId: string): boolean
	for _, message in player.Inbox do
		if message.Kind == "Offer" and message.Payload.QuestId == questId then
			return true
		end
	end
	return false
end
nora.At = deuda.Offer.Place
passTime(nora, 5)
check(not offered(nora, "Loco_D2_Deuda") and not noraData.Story.Active.Loco_D2_Deuda, "Con Cosme sin memoria, las locas en las que recuerda su pasado esperan")
check(playLoco(nora, "Saga_19_Recuerdos") and noraData.Items.AlbumRecuerdos == 1 and not noraData.Story.Flags.CosmeSinMemoria, "19 · Los recuerdos: Cosme vuelve a ser Cosme")
nora.At = deuda.Offer.Place
-- Si en el banco le ofrecieron otra cosa mientras tanto, dice que no (una oferta pendiente tapa las demás)
for _ = 1, 3 do
	if offered(nora, "Loco_D2_Deuda") then
		break
	end
	for _, message in nora.Inbox do
		if message.Kind == "Offer" and message.Payload.QuestId ~= "Loco_D2_Deuda" and not message.Answered then
			message.Answered = true
			fromClient(nora, "Offer", message.Payload.QuestId, false)
		end
	end
	passTime(nora, 5)
end
check(offered(nora, "Loco_D2_Deuda"), "Con la memoria recuperada, ya te ofrecen la deuda galáctica")
fromClient(nora, "Offer", "Loco_D2_Deuda", false)
check(playLoco(nora, "Saga_20_Aliados") and noraData.Story.Flags.AliadosReunidos and noraData.Story.Flags.AliadoCompis, "20 · Los aliados: vienen los que ayudaste en tu vida")
check(playLoco(nora, "Saga_21_Consorcio"), "21 · La caída del Consorcio")
lighting.ClockTime = 22
check(playLoco(nora, "Saga_22_Ancla") and noraData.Story.Choices.Trato and noraData.Story.Choices.Trato.V == "No", "22 · El trato: Cósimo llama a tu puerta y le dices que no")
lighting.ClockTime = 23
-- Ha hecho 4 rarezas: los Restos de la Grieta debilitan a Cósimo en la batalla final
noraData.Story.Memories = noraData.Story.Memories or {}
for _, key in { "BuzonPasado", "PerroBinario", "Piso13", "NubePerdida" } do
	noraData.Story.Memories[key] = os.time()
end
check(playLoco(nora, "Saga_23_Fusion") and noraData.Story.Flags.FusionDetenida and scene(nora, "Grieta_Fusion"), "23 · La Gran Fusión: el cielo se rompe (Grieta_Fusion), aguantar, la oleada y Cósimo se rinde")
check(said(nora, "¿Por qué me pesan las piernas?"), "Con 4 Restos de la Grieta, la colección brilla y Cósimo llega debilitado")
local ConditionsMod = loadModule(ROOT .. "/shared/LifeStory/Conditions")
local fusionSteps = QuestsData.Saga_23_Fusion.Steps
local weakHp, strongHp
for _, step in fusionSteps do
	if step.Type == "Fight" and step.If and step.If.MemoriesAtLeast then
		weakHp = step.HP
	elseif step.Type == "Fight" and step.If and step.If.MemoriesFewer then
		strongHp = step.HP
	end
end
check(weakHp == 6 and strongHp == 10, "Cósimo: 10 golpes sin colección, 6 con 4 Restos o más")
local ctxPocos = { Stage = "Adulto", ClockTime = 12, Weekday = 1, Completed = {}, Flags = {}, Choices = {}, Discovered = {}, Memories = { BuzonPasado = 1 } }
check(ConditionsMod.check({ MemoriesFewer = { N = 4, Of = { "BuzonPasado", "Piso13" } } }, ctxPocos) and not ConditionsMod.check({ MemoriesAtLeast = { N = 2, Of = { "BuzonPasado", "Piso13" } } }, ctxPocos), "Las condiciones cuentan recuerdos de una colección")
check(noraData.Story.Flags.CosimoPerdonado or noraData.Story.Flags.CosimoArregla66B, "Decides qué pasa con Cósimo")
lighting.ClockTime = 12
check(playLoco(nora, "Saga_24_Final") and noraData.Items.AgujaDeOro == 1 and noraData.Story.Flags.SagaCompleta and scene(nora, "Grieta_Final"), "24 · El final: la Grieta se cierra en el patio del cole (Grieta_Final)")
check(nora:GetAttribute("SkyRift") == "Cerrada", "Al final de la saga la Grieta del cielo se cierra para siempre (fase Cerrada)")
passTime(nora, 5)
local quedan = 0
for _ in canonIds(nora) do
	quedan += 1
end
check(quedan == 0, "Terminada la saga, no quedan marcas canónicas en el mapa")

print("\n▶ Rarezas de la Grieta (secundarias cortas: una pieza de colección cada una)")
local function rarezaPlayer(name: string, stage: string)
	local player = newPlayer(name, stage)
	local story = profiles[player].Story
	-- Ya ha jugado la saga (así ninguna canónica empieza sola en mitad de la rareza)
	for id, quest in QuestsData do
		if quest.Canon then
			story.Completed[id] = os.time()
		end
	end
	story.Completed.Uni01b_Residencia = os.time()
	return player, profiles[player]
end
local ruth, ruthData = rarezaPlayer("Ruth", "Nino")
lighting.ClockTime = 12
check(QuestsData.Rareza_Buzon.Requires.Completed[1] == "Saga_02_Grieta", "Las rarezas piden haber visto la Grieta")
check(playLoco(ruth, "Rareza_Buzon") and ruthData.Items.SelloDelAyer == 1 and said(ruth, "yogures del barrio"), "El buzón que escribe al pasado: la carta de ayer, la fuente y el sello")
lighting.ClockTime = 21
check(playLoco(ruth, "Rareza_Farola") and ruthData.Items.BombillaTenor == 1, "La farola que canta ópera (de noche): clase de canto y bombilla tenor")
local teo, teoData = rarezaPlayer("Teo", "Adolescente")
lighting.ClockTime = 12
check(playLoco(teo, "Rareza_Perro") and teoData.Items.ChapaBinaria == 1 and said(teo, "Un robot con amigos"), "El perro que ladra en binario: la biblioteca, la caja y la chapa de Pip")
check(playLoco(teo, "Rareza_Espaguetis") and teoData.Items.TenedorCosmico == 1, "Lluvia de espaguetis: recoger la pasta y enrollar el agujero")
local vera, veraData = rarezaPlayer("Vera", "AdultoJoven")
check(playLoco(vera, "Rareza_Piso13") and veraData.Items.BotonPiso13 == 1 and said(vera, "trescientos años"), "El piso 13: el botón, los exámenes del futuro y Cronos")
check(playLoco(vera, "Rareza_Reloj") and veraData.Items.EngranajeAlReves == 1 and said(vera, "me debes dos euros"), "El reloj que va hacia atrás: los engranajes y la memoria de Iván")
local gael, gaelData = rarezaPlayer("Gael", "Adulto")
gael.Picks = { Semaforo = "Escuchar" }
check(playLoco(gael, "Rareza_Semaforo") and gaelData.Items.LuzAmbar == 1 and said(gael, "Me siento… solo"), "El semáforo con opiniones: le preguntas cómo se siente")
check(playLoco(gael, "Rareza_Nube") and gaelData.Items.GotaNube == 1, "La nube que te sigue: parque, playa y la gota que no se seca")
-- Segundo lote
lighting.ClockTime = 12
check(playLoco(ruth, "Rareza_Columpio") and ruthData.Items.CadenaColumpio == 1 and said(ruth, "Mereció la pena"), "El columpio que va al pasado: las iniciales de tu abu en el banco")
check(playLoco(ruth, "Rareza_Sombra") and ruthData.Items.TizaSombra == 1, "La sombra que se escapa: seguirla y que vuelva a tus zapatillas")
teo.Picks = { Espejo = "Amable" }
check(playLoco(teo, "Rareza_Espejo") and teoData.Items.EsquirlaEspejo == 1 and said(teo, "Tienes buena risa"), "El espejo que contesta: le pides que te diga algo bueno")
check(playLoco(teo, "Rareza_Palomas") and teoData.Items.PlumaCartero == 1, "Las palomas que hacen cola: la carta a la dimensión del pan")
vera.Picks = { Cafe = "Cafe" }
check(playLoco(vera, "Rareza_Cafe") and veraData.Items.VasoConsejos == 1 and said(vera, "Buena decisión"), "La máquina de café que da consejos: eliges café normal")
check(playLoco(vera, "Rareza_Eco") and veraData.Items.SilbatoEco == 1 and said(vera, "Gracias por no rendirte"), "El eco del estadio: tu yo del futuro te da las gracias")
check(playLoco(gael, "Rareza_Contestador") and gaelData.Items.CintaContestador == 1 and said(gael, "lo mejor que nos ha pasado"), "El contestador de 1999: un mensaje de tu familia")
check(playLoco(gael, "Rareza_GatoCaja") and gaelData.Items.CascabelCuantico == 1, "El gato que está y no está: abres la caja y el gato decide")

-- Tercer lote
lighting.ClockTime = 12
ruth.Picks = { Sabor = "Abu" }
check(playLoco(ruth, "Rareza_Helado") and ruthData.Items.CucuruchoRecuerdos == 1 and said(ruth, "Sabe a martes"), "El helado que sabe a recuerdos: una bola con la infancia de tu abu")
check(playLoco(ruth, "Rareza_Charco") and ruthData.Items.PatitoDosLunas == 1 and said(ruth, "aquí se está bien"), "El charco sin fondo: el patito de las dos lunas, al estanque")
check(playLoco(teo, "Rareza_Cancion") and teoData.Items.PartituraSinFin == 1 and said(teo, "Ni en la ducha"), "La canción que no se acaba: los trozos del final y la última nota")
teo.Picks = { Taquilla = "Amigos" }
check(playLoco(teo, "Rareza_Taquilla") and teoData.Items.NotaTaquilla == 1 and said(teo, "Amigos para siempre"), "La taquilla que da a otra taquilla: una amistad de otra dimensión")
check(playLoco(vera, "Rareza_Fotocopiadora") and veraData.Items.TonerVerde == 1 and said(vera, "Fotocopias con vida propia"), "La fotocopiadora que copia personas: dos Candelas de papel")
vera.Picks = { Wifi = "Consejo" }
check(playLoco(vera, "Rareza_Wifi") and veraData.Items.ModemPitido == 1 and said(vera, "colección de cómics"), "El wifi que se conecta a 1987: un consejo para Marisa")
check(playLoco(gael, "Rareza_Lavadora") and gaelData.Items.PinzaMultiversal == 1 and said(gael, "la dimensión de al lado"), "La lavadora multiversal: el programa «Devolver»")
gael.Picks = { Minutos = "Llamar" }
check(playLoco(gael, "Rareza_Cajero") and gaelData.Items.BilleteMinutos == 1 and said(gael, "te has movido por dentro"), "El cajero que da minutos: llamas a tu familia")
do
	local porEtapa = {}
	local restosSaga = {}
	for id, quest in QuestsData do
		if id:sub(1, 7) == "Rareza_" then
			porEtapa[quest.Type] = (porEtapa[quest.Type] or 0) + 1
		end
	end
	local seis = true
	for _, stage in { "Infancia", "Adolescencia", "Universidad", "Vida adulta" } do
		if porEtapa["Rareza de la Grieta · " .. stage] ~= 6 then
			seis = false
		end
	end
	check(seis, "Seis rarezas por etapa")
	-- Todas las rarezas cuentan para los Restos de la Grieta del final
	local fusionIf
	for _, step in QuestsData.Saga_23_Fusion.Steps do
		if step.Type == "Fight" and step.If and step.If.MemoriesAtLeast then
			fusionIf = step.If.MemoriesAtLeast.Of
		end
	end
	for _, key in fusionIf or {} do
		restosSaga[key] = true
	end
	local todas = fusionIf ~= nil
	for id, quest in QuestsData do
		if id:sub(1, 7) == "Rareza_" and not restosSaga[quest.Memory] then
			todas = false
			print("    Falta en RESTOS: " .. tostring(quest.Memory))
		end
	end
	check(todas, "Cada rareza cuenta como Resto de la Grieta en la batalla final")
end

print("\n▶ Misiones de aliados (cada aliado vuelve antes de «Todos los aliados»)")
local function aliadoPlayer(name: string, stage: string)
	local player, data = rarezaPlayer(name, stage)
	for _, id in { "Loco_N2_Bigotes", "Loco_N5_Perez", "Loco_U1_Monte", "Loco_U2_Rex", "Loco_D4_Gnomos", "Loco_D5_Malvado" } do
		data.Story.Completed[id] = os.time()
	end
	return player, data
end
check(QuestsData.Aliado_Rex.Requires.Flags[1] == "RexSeQueda" and QuestsData.Aliado_Cronos.Requires.Flags[1] == "CronosAliado", "Rex y Cronos solo vuelven si les ayudaste (Rex se quedó, Cronos se pasó a tu bando)")
check(table.find(QuestsData.Aliado_Bigotes.Requires.Completed, "Loco_N2_Bigotes") ~= nil and table.find(QuestsData.Aliado_Malvado.Requires.Completed, "Loco_D5_Malvado") ~= nil, "Cada aliado pide su misión loca")
local alba, albaData = aliadoPlayer("Alba", "AdultoJoven")
albaData.Story.Flags.DuqueDeGatonia = true
albaData.Story.Flags.RexSeQueda = true
albaData.Story.Flags.CronosAliado = true
albaData.Story.Flags.RataContratada = true
albaData.Story.Flags.CosmeSecuestrado = true -- Cosme aún no ha vuelto: nadie da por hecho que está
lighting.ClockTime = 12
check(playLoco(alba, "Aliado_Bigotes") and albaData.Items.BandaCanciller == 1 and albaData.Story.Memories.GuardiaGatuna ~= nil and said(alba, "del Cojín: tu título sigue en vigor"), "Bigotes: la visita de Estado, las cucarachas a manguerazos y la Guardia Gatuna")
alba.Picks = { Alegato = "Letra" }
check(playLoco(alba, "Aliado_Rex") and albaData.Items.TarjetaRex == 1 and albaData.Story.Memories.AbogadoRex ~= nil and said(alba, "Lees la letra pequeña"), "Rex: las pruebas, la letra pequeña y su primer juicio ganado")
alba.Picks = { Declaracion = "Verdad" }
check(playLoco(alba, "Aliado_Cronos") and albaData.Items.Formulario42B == 1 and albaData.Story.Memories.ExpedienteCronos ~= nil and said(alba, "La verdad no necesita sello"), "Cronos: las firmas, la ventanilla 42 y el expediente limpio")
check(said(alba, "Firmo yo por los dos"), "Con Cosme secuestrado, Pip firma por los dos")
lighting.ClockTime = 23
check(playLoco(alba, "Aliado_Perez") and albaData.Items.CarnetSindical == 1 and albaData.Story.Memories.MuelaDelJuicio ~= nil and said(alba, "jefa de turno"), "El Ratón Pérez: la muela del juicio y el saco de dientes del Consorcio")
check(playLoco(alba, "Aliado_Noz") and albaData.Items.ClaquetaAlien == 1 and albaData.Story.Memories.TemporadaFinal ~= nil and said(alba, "aviones de Andrómeda"), "La Capitana Ñoz: la promo del final de temporada")
local dani, daniData = aliadoPlayer("Dani", "Adulto")
daniData.Story.Flags.MalvadoRedimido = true
dani.Picks = { Espias = "Devolver", Leccion = "Nadie" }
lighting.ClockTime = 23
check(playLoco(dani, "Aliado_Gnomos") and daniData.Items.GorroGnomo == 1 and daniData.Story.Memories.ConsejoGnomos ~= nil and said(dani, "Id a espiar a vuestra abuela"), "Los gnomos: los gnomos espía de plástico y el consejo de los jardines")
lighting.ClockTime = 12
check(playLoco(dani, "Aliado_Malvado") and daniData.Items.DiplomaBondad == 1 and daniData.Story.Memories.ClasesDeBondad ~= nil and said(dani, "multado tres veces"), "Tu yo malvado: clases de ser bueno")
do
	-- En «Todos los aliados» (saga 20), cada misión de aliado tiene su frase
	local saga20 = QuestsData.Saga_20_Aliados
	local citadas = {}
	for _, dlg in saga20.Dialogues do
		for _, line in dlg.Lines do
			for _, id in (line.If and line.If.Completed) or {} do
				citadas[id] = true
			end
		end
	end
	local todas = true
	for id in QuestsData do
		if id:sub(1, 7) == "Aliado_" and not citadas[id] then
			todas = false
			print("    Sin frase en la saga 20: " .. id)
		end
	end
	check(todas, "En «Todos los aliados», cada aliado recuerda su misión")
end

print("\n▶ Misiones locas · Adolescencia (el futuro, los lápices, el DJ alienígena, Pip, Zoltán)")
local iris = newPlayer("Iris", "Adolescente")
local irisData = profiles[iris]
iris.Prefer = { "Prometo no publicar", "Para saber lo que ya sé", "Un DJ alienígena", "Nadie sabe para qué", "Que todo el mundo me haga caso", "La guardaré" }
lighting.ClockTime = 12
check(playLoco(iris, "Loco_A1_Futuro") and irisData.Items.MovilFuturo == 1 and irisData.Story.Flags.SinCalcetin, "Mensajes del futuro: tu yo de 2036, el calcetín viral y la huida de la Aduana del Tiempo")
check(playLoco(iris, "Loco_A2_Lapices") and irisData.Items.LapizDimensional == 1, "La Dimensión Examen: huir de los lápices gigantes y la Última Pregunta")
check(playLoco(iris, "Loco_A3_Concierto") and irisData.Items.CascosAntiHipnosis == 1 and said(iris, "ZUMBIDO FAN CLUB"), "El concierto hipnótico: cascos con la música de los helados para los fans y el DJ")
check(playLoco(iris, "Loco_A4_Pip") and irisData.Items.PipBolsillo == 1 and said(iris, "Un 97 %"), "La crisis de Pip: tres pistas, la persecución y el propósito")
check(playLoco(iris, "Loco_A5_Zoltan") and irisData.Items.FichaDorada == 1 and irisData.Story.Flags.DeseoCaso, "Zoltán: un deseo al pie de la letra, la huida y la ficha dorada")

print("\n▶ Misiones locas · Universidad (la luz del monte, Rex, el multiverso, la fiesta, el examen del universo)")
local uxia = newPlayer("Uxia", "AdultoJoven")
local uxiaData = profiles[uxia]
uxia.Prefer = { "Pues yo sí voy", "La verdad: alienígenas", "¡Bienvenido!", "Rex es el mejor", "No. Cosme es insoportable" }
uxia.Picks = { CualCosme = "Rescatar", Acusar = "Bien" }
lighting.ClockTime = 12
check(QuestsData.Loco_U1_Monte ~= nil, "La luz del Monte del Silencio existe")
local monte = false
do
	local story = uxiaData.Story
	for _ = 1, 12 do
		if story.Active.Loco_U1_Monte then
			break
		end
		uxia.At = "Universidad"
		passTime(uxia, 5)
		if received(uxia, "Offer", "La luz del Monte del Silencio") then
			fromClient(uxia, "Offer", "Loco_U1_Monte", true)
		end
	end
	-- De día, la cima está vacía: la luz solo sale de madrugada
	for _ = 1, 20 do
		local _, step = questStep(uxia, "Loco_U1_Monte")
		if step and step.Hours then
			break
		end
		if step then
			doStep(uxia, "Loco_U1_Monte", step)
		end
		task.wait(0.6)
	end
	uxia.At = "CimaMonte"
	passTime(uxia, 5)
	local _, still = questStep(uxia, "Loco_U1_Monte")
	check(still and still.Hours ~= nil, "A mediodía en la cima no pasa nada (la luz sale entre las 2 y las 5)")
	lighting.ClockTime = 3
	monte = playQuest(uxia, "Loco_U1_Monte", 250)
end
check(monte and uxiaData.Items.PistolaRayos == 1 and uxiaData.Story.Flags.DeclaracionAlien, "Sube de madrugada, huye de la luz, derrota a los tres alienígenas y se queda la pistola de rayos")
check(said(uxia, "Terrícolas en apuros") and said(uxia, "Tres semanas abriendo botes de pepinillos"), "Era un reality alienígena; Fermín y los desaparecidos vuelven")
check(uxiaData.Story.Memories.Abduccion ~= nil, "Recuerdo: la luz del Monte del Silencio")
lighting.ClockTime = 16
check(playLoco(uxia, "Loco_U2_Rex") and uxiaData.Items.DienteRex == 1 and uxiaData.Story.Flags.RexSeQueda, "Mi compañero de piso es un dinosaurio: huida de la Aduana del Tiempo y Rex se queda")
check(playLoco(uxia, "Loco_U3_Multiverso") and uxiaData.Items.MandoDimensiones == 1 and uxiaData.Story.Flags.CosmeOriginal, "Las tres Valmar: gatos, tú de alcalde y un Cosme aburrido; rescatas al de siempre")
check(said(uxia, "Yo no soy tu Cosme"), "Giro: el Cosme que te acompañaba era de otra dimensión")
lighting.ClockTime = 22
check(playLoco(uxia, "Loco_U4_Fiesta") and uxiaData.Items.GafasImpostores == 1, "La fiesta de los cambiaformas: pistas, acusación y gafas de ver impostores")
lighting.ClockTime = 12
check(playLoco(uxia, "Loco_U5_Examen") and uxiaData.Items.DiplomaUniverso == 1 and uxiaData.Story.Flags.SalvasteACosme, "El examen del universo: la Tierra aprueba gracias a ti")

print("\n▶ Universidad · secundarias con los compañeros (zumo de mora, fiesta, acampada, playa, Pabellón 0, cita, Tito)")
local nora = newPlayer("Nora", "AdultoJoven")
local noraData = profiles[nora]
noraData.Money = 300
noraData.Story.Completed.Uni01b_Residencia = os.time()
noraData.Story.Completed.UniEx1_Enero = os.time()
nora.Prefer = { "«Perdone. Bajamos la música", "Una de miedo de verdad", "«Me gustas", "Les cuentas todo" }
nora.Picks = { Culpable = "Suave", Cita = "Luca" }
lighting.ClockTime = 12
check(playLoco(nora, "UniS_Zumo") and noraData.Items.ZumoMora == 1 and said(nora, "Moras del Monte del Silencio"), "La guerra del zumo de mora: era Iván, sonámbulo (moras del Monte del Silencio)")
lighting.ClockTime = 19
check(playLoco(nora, "UniS_Fiesta") and noraData.Story.Flags.FiestaTranquila and said(nora, "concursos de twist"), "Fiesta en casa de Adrián: el vecino acaba enseñando twist")
check(playLoco(nora, "UniS_Acampada") and noraData.Items.TazaCampamento == 1 and said(nora, "¿Mi abuela vende zumo a los alienígenas?"), "Acampada en el monte: historias de miedo y Blorp viene a por moras")
lighting.ClockTime = 12
check(playLoco(nora, "UniS_Playa") and noraData.Items.PinzaDeOro == 1 and said(nora, "Tratado de las Mareas de 1734"), "Día de playa: voley, castillos y Don Pinzas, cangrejo abogado")
check(playLoco(nora, "UniS_Pabellon0") and noraData.Items.FotoCosmeCosimo == 1 and noraData.Story.Flags.VioPabellon0, "El Pabellón 0: el laboratorio donde Cosme y Cósimo abrieron la Grieta")
lighting.ClockTime = 19
check(playLoco(nora, "UniS_Cita") and noraData.Story.Flags.TienePareja and said(nora, "Ahora hay alguien con quien quiero ver atardeceres"), "Una cita (opcional, con un personaje): helado y atardecer con Luca")
lighting.ClockTime = 12
check(playLoco(nora, "UniS_Tito") and noraData.Story.Flags.TitoDescubierto and noraData.Story.Flags.CompisSabenGrieta, "El compañero que no existe: un espía del Consorcio; Iván y Candela ya saben lo de la Grieta")

print("\n▶ Misiones locas · Vida adulta (el lunes eterno, la deuda galáctica, la tostadora, los gnomos, tu yo malvado)")
local olga = newPlayer("Olga", "Adulto")
local olgaData = profiles[olga]
olgaData.Money = 500
olga.Prefer = { "¿Por qué querías guardarte", "Un duelo", "Vuelve a tu dimensión" }
olga.Picks = { Deuda = "Resistir" }
lighting.ClockTime = 10
check(playLoco(olga, "Loco_D1_Lunes") and olgaData.Items.TazaTiempo == 1 and said(olga, "¡Martes! ¡Qué martes!"), "El lunes eterno: pistas en la oficina, la cafetera X-9000 y por fin martes")
check(playLoco(olga, "Loco_D2_Deuda") and olgaData.Items.TarjetaGalactica == 1 and said(olga, "Terrícolas: tercos"), "La deuda galáctica: el bocadillo de Cosme en Plutón y resistir a los cobradores")
check(olgaData.Money == 600, "Resistir no cuesta dinero (y dan 100 de bono)")
check(playLoco(olga, "Loco_D3_Tostadora") and olgaData.Items.TostadoraCosme == 1 and said(olga, "tengo miedo de olvidarme"), "Cosme en una tostadora: la rebelión de los electrodomésticos y su miedo a olvidar")
lighting.ClockTime = 18
check(playLoco(olga, "Loco_D5_Malvado") and olgaData.Items.PerillaMalvada == 1 and olgaData.Story.Flags.MalvadoRedimido, "Tu yo malvado: huir del portal, arrancarle la perilla y darle otra oportunidad")
lighting.ClockTime = 23
local barked = function(player, fragment)
	for _, text in player.Barks do
		if tostring(text):find(fragment, 1, true) then
			return true
		end
	end
	return false
end
check(playLoco(olga, "Loco_D4_Gnomos") and olgaData.Items.GnomoAliado == 1 and olgaData.Story.Choices.Gnomos.V == "Guerra" and barked(olga, "Tengo vértigo") and said(olga, "Firmamos"), "La noche de los gnomos: duelo con el Gran Gnomo y tratado de paz")

print("\n▶ Gadgets: las recompensas exclusivas se usan desde la mochila")
local ItemsData = loadModule(ROOT .. "/shared/Items")
local gadgets = 0
for _, id in { "Tirachinas", "PistolaBurbujas", "RayoEncogedor", "MovilFuturo", "CascosAntiHipnosis", "PipBolsillo", "PistolaRayos", "MandoDimensiones", "GafasImpostores", "TazaTiempo", "TostadoraCosme" } do
	local item = ItemsData.get(id)
	if item and item.Kind == "Gadget" and item.Effect then
		gadgets += 1
	end
end
check(gadgets == 11, "11 gadgets exclusivos, cada uno con su efecto")
local exclusive = 0
for _, quest in QuestsData do
	-- (el premio llega al final o en un paso: el tirachinas te lo da la abuela al abrir el baúl)
	local gives = quest.Rewards ~= nil and quest.Rewards.Items ~= nil and next(quest.Rewards.Items) ~= nil
	local function scan(steps)
		for _, step in steps or {} do
			if step.Effects and step.Effects.Items and next(step.Effects.Items) ~= nil then
				gives = true
			end
			scan(step.Steps)
		end
	end
	scan(quest.Steps)
	if quest.Id and quest.Id:sub(1, 5) == "Loco_" and gives then
		exclusive += 1
	end
end
check(exclusive == 21, "21 misiones locas (6 de infancia y 5 en cada otra etapa), todas con recompensa exclusiva")

print("\n▶ Las partidas se pueden guardar (DataStore/JSON: nada que Roblox rechace, tamaño)")
do
	local problems, biggest = H.saveProblems()
	for _, text in problems do
		print("    · " .. text)
	end
	H.check(#problems == 0, ("nada que el DataStore rechace (%d problemas)"):format(#problems))
	H.check(biggest < 3500000, ("la mayor partida ocupa %d caracteres (límite 4.194.304)"):format(biggest))
end
print(("\n%s"):format(if H.failures == 0 then "✅ Todo correcto" else ("❌ %d fallos"):format(H.failures)))
process.exit(if H.failures == 0 then 0 else 1)
