-- Prueba de las TRANSICIONES DE CAPÍTULO y del ENCADENADO de escenas (Lune, fuera de Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-transiciones.luau
--
-- La queja de la v107 (móvil): al acabar una cinemática empezaba otra y entre medias se veía un segundo
-- toda la interfaz; el montaje de bebé a niño enseñaba la puerta del colegio con Lucía y aparecías en
-- tu casa con su frase todavía en pantalla; los rótulos de las fotos salían a la vez que una frase.
-- Comprueba:
--   1. Rótulos y frases (shared/LifeStory/SceneTiming): rótulo primero y frase después, nunca a la vez;
--      la frase de un personaje se lee entera antes del corte a otro sitio; dos frases no se pisan. En
--      TODAS las cinemáticas viejas (Cinematics.luau, también las que no prueba test-cineplanos), los
--      montajes de cambio de etapa y el final de la vida (Happenings/Etapas), las cabeceras y finales de
--      capítulo, el nacimiento y el ventanal. Del resto de escenas solo se cuentan (aviso, no falla).
--   2. El sitio: cada montaje que acaba donde sigue la historia (Montaje.Stage) lo lanza un paso
--      Transition que te lleva allí; el mundo nuevo del montaje se ve allí; y lo primero que se juega
--      después pasa allí (o es ir andando a otro sitio, nunca una escena en otro sitio). En particular,
--      el primer día de colegio sigue en la puerta del colegio, sin pasar por casa.
--   3. El encadenado: el montaje es el final del capítulo que acaba y la cabecera del siguiente (lleva
--      sus rótulos), así que sus cinemáticas viejas no van detrás; entre el montaje y volver a jugar no
--      hay más de una escena de cámara.
--   (El puente entre dos escenas —negro, sin interfaz— lo prueba scripts/test-cinematic.luau.)

local L = require("./lib/ModuleLoader")

local check = L.check

local Sequencer = L.load("src/shared/LifeStory/Sequencer")
local HappeningIndex = L.load("src/shared/LifeStory/HappeningIndex")
local Cinematics = L.load("src/shared/LifeStory/Cinematics")
local Chapters = L.load("src/shared/LifeStory/Chapters")
local Quests = L.load("src/shared/LifeStory/Quests")
local Conditions = L.load("src/shared/LifeStory/Conditions")
local SceneTiming = L.load("src/shared/LifeStory/SceneTiming")

local MONTAGES = { "Montaje_Bebe_Nino", "Montaje_Nino_Adolescente", "Montaje_Adolescente_Joven", "Montaje_Joven_Adulto" }

---------------------------------------------------------------------
print("0. Las reglas de tiempo detectan lo que se vio en la v107")
---------------------------------------------------------------------
do
	-- El rótulo «La cocina, la tele…» a la vez que la frase de Abu
	local bad = {
		Id = "Prueba",
		Duration = 10,
		Lines = { { At = 1, Until = 4.4, Text = "¡Mira, mira! ¡Ya viene sin agarrarse!", Speaker = "Abu" } },
		Titles = { { At = 3, Until = 6.6, Text = "La cocina, la tele, los juguetes" } },
		Cuts = {},
	}
	local kinds = {}
	for _, p in SceneTiming.check(bad) do
		kinds[p.Kind] = true
	end
	check(kinds.TituloYFrase, "un rótulo a la vez que una frase se detecta")
	-- «¿Primer día? Pasad, pasad» de Lucía encima del plano de tu casa (corte con fundido a 6 s)
	local away = {
		Id = "Prueba",
		Duration = 12,
		Lines = { { At = 4, Until = 10.2, Text = "¡Buenos días! ¿Primer día? Pasad, pasad.", Speaker = "Lucia" } },
		Titles = {},
		Cuts = { { At = 6, Kind = "Dip" } },
	}
	local found = false
	for _, p in SceneTiming.check(away) do
		found = found or p.Kind == "FraseFueraDeSitio"
	end
	check(found, "la frase de un personaje que pasa al plano de otro sitio se detecta")
	-- La del narrador puede pasar por encima de un corte
	away.Lines[1].Speaker = "Narrador"
	check(#SceneTiming.check(away) == 0, "la voz del narrador sí puede pasar por encima de un corte")
	-- Dos alternativas (una decisión u otra) no se pisan
	check(SceneTiming.exclusive({ If = { Choices = { PromesaAdulta = "Viaje" } } }, { If = { Choices = { PromesaAdulta = "Hijos" } } }), "dos valores de la misma decisión son alternativas")
	check(SceneTiming.exclusive({ If = { Flags = { "X" } } }, { IfNot = { Flags = { "X" } } }), "una marca y su contraria son alternativas")
	check(not SceneTiming.exclusive({ If = { Flags = { "X" } } }, { If = { Flags = { "Y" } } }), "dos marcas distintas pueden darse a la vez")
end

---------------------------------------------------------------------
print("1. Rótulos y frases en las transiciones (y en todas las cinemáticas viejas)")
---------------------------------------------------------------------
local strict: { [string]: string } = {} -- id -> sistema ("Vieja" | "Motor")
for id in Cinematics do
	strict[id] = "Vieja"
end
for id, def in HappeningIndex.all() do
	if HappeningIndex.groupOf(id) == "Etapas" then
		strict[id] = "Motor"
	end
	if type(def) == "table" and def.Montaje then
		strict[id] = "Motor"
	end
end
for _, chapter in Chapters do
	for _, id in { chapter.IntroCinematic, chapter.OutroCinematic } do
		if id and HappeningIndex.has(id) then
			strict[id] = "Motor"
		end
	end
end
strict.Bebe_VentanalFamilia = "Motor" -- (justo antes del montaje de bebé a niño)

local function normOf(id: string): any
	if strict[id] == "Vieja" or (Cinematics[id] and not HappeningIndex.has(id)) then
		return SceneTiming.fromCinematic(id, Cinematics[id])
	end
	local def = HappeningIndex.get(id)
	local ok, timeline = pcall(Sequencer.compile, id, def)
	if not ok then
		return nil
	end
	return SceneTiming.fromTimeline(id, timeline)
end

local ids = {}
for id in strict do
	table.insert(ids, id)
end
table.sort(ids)
for _, id in ids do
	local norm = normOf(id)
	check(norm ~= nil, ("%s se puede revisar (%s)"):format(id, strict[id]))
	if norm then
		local problems = SceneTiming.check(norm)
		for _, p in problems do
			print(("     %s · %s"):format(p.Kind, p.Detail))
		end
		check(#problems == 0, ("%s: rótulo primero, cada frase en su sitio y sin pisarse (%s, %d frases, %d rótulos)"):format(id, strict[id], #norm.Lines, #norm.Titles))
	end
end
-- Las demás escenas (de misiones): solo aviso (en el cliente, la frase espera a que se vaya el rótulo
-- y un corte a otro sitio quita la frase de un personaje: HappeningClient y Cinematics)
local others, withProblems = 0, {}
for id, def in HappeningIndex.all() do
	if not strict[id] then
		others += 1
		local ok, timeline = pcall(Sequencer.compile, id, def)
		if ok and #SceneTiming.check(SceneTiming.fromTimeline(id, timeline)) > 0 then
			table.insert(withProblems, id)
		end
	end
end
table.sort(withProblems)
print(("  ℹ️ otras escenas: %d; con avisos de tiempo (los arregla el cliente al reproducirlas): %d%s"):format(
	others, #withProblems, if #withProblems > 0 then " · " .. table.concat(withProblems, ", ") else ""))

---------------------------------------------------------------------
print("2. El sitio: el montaje acaba donde sigue la historia")
---------------------------------------------------------------------
-- Sitios que son el mismo sitio para la historia (tu casa por dentro y por fuera; la puerta del cole)
local GROUPS = {
	{ "CasaFamiliar", "HomeSalon", "HomeCocina", "HomeDormitorio", "CasaDespertar", "CasaArmario", "CasaMochila", "CasaDesayuno", "CasaCama", "CasaEspejo" },
	{ "EntradaColegio", "SpotProfesorEntrada", "SpotPadres1", "SpotPadres2", "SpotPadres3" },
}
local function samePlace(a: string?, b: string?): boolean
	if a == nil or b == nil then
		return false
	end
	if a == b then
		return true
	end
	for _, group in GROUPS do
		if table.find(group, a) and table.find(group, b) then
			return true
		end
	end
	return false
end
local function placeOf(spec: any): string?
	if type(spec) == "string" then
		return (spec:gsub("^Place:", ""))
	elseif type(spec) == "table" then
		return spec.Place
	end
	return nil
end

-- Una partida de mentira para las condiciones de los pasos
local function lifeWith(flags: { string }, stage: string): any
	local set = {}
	for _, f in flags do
		set[f] = 1
	end
	return {
		Stage = stage,
		ClockTime = 9,
		Weekday = 1,
		Completed = {},
		Flags = set,
		Choices = {},
		Discovered = {},
		Memories = {},
		Rel = {},
		Traits = {},
	}
end

-- El paso Transition que lanza cada montaje
local launchers: { [string]: { Quest: string, Step: { [string]: any } } } = {}
for questId, quest in Quests do
	for _, step in quest.Steps or {} do
		if step.Type == "Transition" and type(step.Cinematic) == "string" and HappeningIndex.has(step.Cinematic) then
			local def = HappeningIndex.get(step.Cinematic)
			if def and def.Montaje then
				for _, id in MONTAGES do
					if HappeningIndex.get(id) == def then
						launchers[id] = { Quest = questId, Step = step }
					end
				end
			end
		end
	end
end

-- Lo primero que se juega en un capítulo con estas marcas: { Kind, Place, Step }
local LOCATED = { Scene = true, Talk = true, Cinematic = true, Choice = true, Use = true }
local function firstPlay(chapterId: string, ctx: any): { [string]: any }?
	local chapter = Chapters[chapterId]
	local questId = chapter and chapter.Main[1]
	local quest = questId and Quests[questId]
	if not quest then
		return nil
	end
	for index, step in quest.Steps do
		if step.If and not Conditions.check(step.If, ctx) then
			continue
		end
		local teleport = placeOf(step.Teleport)
		if teleport then
			return { Kind = "Escena", Place = teleport, Index = index, Quest = questId }
		end
		if LOCATED[step.Type] then
			local places = {}
			for _, actor in step.Actors or {} do
				if type(actor) == "table" and actor.Place and actor.If == nil then
					table.insert(places, actor.Place)
				end
			end
			return { Kind = "Escena", Places = places, Index = index, Quest = questId, Type = step.Type }
		end
		if step.Type == "Reach" or step.Type == "Event" then
			return { Kind = "Ir", Place = step.Place, Index = index, Quest = questId }
		end
	end
	return nil
end

for _, id in MONTAGES do
	local def = HappeningIndex.get(id)
	local stage = def.Montaje.Stage
	local launcher = launchers[id]
	check(launcher ~= nil, ("%s: lo lanza un paso Transition"):format(id))
	if not stage or not launcher then
		-- (el colegio años después de Joven → Adulto es un epílogo: la llegada te enseña donde estás)
		check(def.Montaje.Next == "Adulto_TuVida", ("%s: sin sitio propio solo el epílogo (juego libre después)"):format(id))
		continue
	end
	local step = launcher.Step
	check(samePlace(placeOf(step.Teleport), stage), ("%s: el paso que lo lanza te lleva a %s (%s)"):format(id, stage, tostring(placeOf(step.Teleport))))
	-- El mundo nuevo (los planos de antes de la llegada) se ve en ese sitio
	local T = def.Timing
	local seen = false
	for _, shot in def.Tracks.Camera do
		if shot.At >= T.NewWorld - 1e-6 and shot.At < T.Arrival - 1e-6 then
			for _, field in { "Fixed", "To", "Look" } do
				local anchor = type(shot[field]) == "table" and shot[field][1]
				local spec = anchor and def.Anchors[anchor]
				if type(spec) == "string" and samePlace(placeOf(spec), stage) then
					seen = true
				end
			end
		end
	end
	check(seen, ("%s: el mundo nuevo se ve en %s, donde acabas"):format(id, stage))
	-- Lo primero que se juega después, en cada capítulo que puede empezar
	local flags = {}
	for _, f in (step.Effects and step.Effects.Flags) or {} do
		table.insert(flags, f)
	end
	for nextId in string.gmatch(def.Montaje.Next, "[^|]+") do
		local chapter = Chapters[nextId]
		local extra = table.clone(flags)
		if nextId == "Joven_Universidad" then
			table.insert(extra, "VaALaUniversidad")
		elseif nextId == "Adulto_VolarDelNido" then
			table.insert(extra, "EmpiezaATrabajar")
		end
		local first = firstPlay(nextId, lifeWith(extra, def.Montaje.To))
		check(first ~= nil, ("%s → %s: hay algo que jugar"):format(id, nextId))
		if first then
			local ok
			if first.Kind == "Ir" then
				ok = true -- (vas andando: no hay escena en otro sitio)
			elseif first.Place then
				ok = samePlace(first.Place, stage)
			else
				ok = false
				for _, place in first.Places do
					ok = ok or samePlace(place, stage)
				end
			end
			check(ok, ("%s → %s: lo primero (%s, paso %d) pasa en %s"):format(id, nextId, first.Quest, first.Index, stage))
		end
		check(chapter ~= nil, ("%s → %s existe"):format(id, nextId))
	end
end

-- El caso de la v107: después del montaje, el primer día sigue EN LA PUERTA del colegio
do
	local first = firstPlay("Nino_ElColegio", lifeWith({ "PrimerDiaEnElCole" }, "Nino"))
	local quest = Quests.Cole01_PrimerDia
	local step = first and quest.Steps[first.Index]
	check(step ~= nil and step.Type == "Scene" and step.Dialogue == "Entrada", "el primer día de colegio empieza en la entrada (la escena «Entrada»), sin pasar por casa")
	local skipped = 0
	for i = 1, (first and first.Index or 1) - 1 do
		local s = quest.Steps[i]
		if s.If and not Conditions.check(s.If, lifeWith({ "PrimerDiaEnElCole" }, "Nino")) then
			skipped += 1
		end
	end
	check(skipped == (first and first.Index or 1) - 1, "la mañana en casa y el camino se saltan (no se juegan en otro sitio)")
	-- Sin venir del montaje (partidas de antes), el día empieza en casa como siempre
	local old = firstPlay("Nino_ElColegio", lifeWith({}, "Nino"))
	check(old ~= nil and samePlace(old.Place, "HomeDormitorio"), "sin la marca del montaje, el día empieza en casa como siempre")
	local bebe = launchers.Montaje_Bebe_Nino
	check(bebe and bebe.Step.Effects and bebe.Step.Effects.Items and bebe.Step.Effects.Items.MochilaCole == 1, "llegas al colegio con tu mochila nueva")
end

---------------------------------------------------------------------
print("3. Encadenado: el montaje es el final y la cabecera; luego, a jugar")
---------------------------------------------------------------------
local function covered(def: any, chapterId: string, phase: string): boolean
	local m = def.Montaje
	if phase == "Outro" then
		return m.Chapter == chapterId
	end
	for id in string.gmatch(m.Next or "", "[^|]+") do
		if id == chapterId then
			return true
		end
	end
	return false
end
for _, id in MONTAGES do
	local def = HappeningIndex.get(id)
	local T = def.Timing
	-- Lleva los rótulos: final del capítulo que acaba (en el cierre) y cabecera del siguiente (en la llegada)
	local endCard, headCard = false, false
	for _, title in def.Tracks.Titles do
		endCard = endCard or (title.At < T.Memories and title.Sub == "Fin del capítulo")
		headCard = headCard or title.At >= T.Arrival + 2
	end
	check(endCard, ("%s: lleva el rótulo de fin del capítulo"):format(id))
	check(headCard, ("%s: lleva la cabecera del capítulo nuevo (después del rótulo del salto de años)"):format(id))
	-- Cuántas escenas de cámara hasta volver a jugar
	local chapter = Chapters[def.Montaje.Chapter]
	for nextId in string.gmatch(def.Montaje.Next, "[^|]+") do
		local scenes = 1 -- el montaje
		if chapter and chapter.OutroCinematic and not covered(def, chapter.Id, "Outro") then
			scenes += 1
		end
		local nextChapter = Chapters[nextId]
		if nextChapter and nextChapter.IntroCinematic and not covered(def, nextId, "Intro") then
			scenes += 1
		end
		local launcher = launchers[id]
		local flags = {}
		for _, f in (launcher and launcher.Step.Effects and launcher.Step.Effects.Flags) or {} do
			table.insert(flags, f)
		end
		local ctx = lifeWith(flags, def.Montaje.To)
		local quest = nextChapter and Quests[nextChapter.Main[1]]
		for _, step in (quest and quest.Steps) or {} do
			if step.If and not Conditions.check(step.If, ctx) then
				continue
			end
			if step.Type == "Cinematic" or (step.Type == "Transition" and step.Cinematic) then
				scenes += 1
			else
				break
			end
		end
		check(scenes <= 2, ("%s → %s: %d escena(s) de cámara seguidas antes de jugar"):format(id, nextId, scenes))
		check(covered(def, nextId, "Intro"), ("%s → %s: su cabecera vieja no va detrás del montaje"):format(id, nextId))
	end
	check(covered(def, def.Montaje.Chapter, "Outro"), ("%s: el final viejo de %s no va detrás del montaje"):format(id, def.Montaje.Chapter))
end

-- El servidor usa la misma regla (LifeStoryService: montageCovers). Se lee su código: si alguien quita
-- la regla, esta prueba lo dice.
do
	local fs = require("@lune/fs")
	local source = fs.readFile("src/server/Services/LifeStoryService.luau")
	check(source:find("montageCovers(rt, id, \"Intro\")", 1, true) ~= nil, "el servidor no pone la cabecera vieja detrás del montaje")
	check(source:find("montageCovers(rt, chapter.Id, \"Outro\")", 1, true) ~= nil, "el servidor no pone el final viejo detrás del montaje")
	check(source:find("CinematicService.expectFollowUp", 1, true) ~= nil, "el servidor avisa a la pantalla cuando va otra escena detrás (puente sin interfaz)")
	local baby = fs.readFile("src/server/Services/BabyService.luau")
	check(baby:find("expectFollowUp", 1, true) ~= nil and baby:find("waitFor(player, \"Bebe_VentanalFamilia\"", 1, true) ~= nil,
		"el ventanal avisa de que viene el montaje y lo lanza cuando la escena acaba en la pantalla")
end

L.finish("test-transiciones")
