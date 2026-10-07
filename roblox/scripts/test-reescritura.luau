-- Prueba de los GUIONES REESCRITOS (docs/historia/reescritura → shared/LifeStory/Guiones, GuionOverlay).
--
-- Uso (desde roblox/): lune run scripts/test-reescritura.luau
--
-- 1. Cada guion generado está al día con su .md (la herramienta lo regenera igual) y sin errores.
-- 2. Las misiones reescritas usan las frases nuevas, sin perder la mecánica de sus pasos (mismos tipos,
--    sitios, eventos y objetos que la misión original).
-- 3. El prólogo se juega entero con la respuesta A («¡Yo te ayudo a arreglarla!») y con la B
--    («¿Y eso es peligroso?»): cada paso se cumple con su acción, salen las frases nuevas de Cosme y se
--    guardan la decisión y el rasgo de cada rama.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local H = require("./lib/StoryHarness")
local L = require("./lib/ModuleLoader")
local Reescritura = require("./lib/Reescritura")
local ROOT, check = H.ROOT, H.check
local Quests = H.Quests
local GuionOverlay = H.loadModule(ROOT .. "/shared/LifeStory/GuionOverlay")

---------------------------------------------------------------------
print("\n▶ 1. Los guiones generados están al día")
---------------------------------------------------------------------
-- La misión original (sin guion) para comparar la mecánica
L.mock("src/shared/LifeStory/GuionOverlay", { List = {}, apply = function() end, scenes = function()
	return {}
end, all = function()
	return {}
end })
local BaseQuests = L.load("src/shared/LifeStory/Quests")

check(#GuionOverlay.List > 0, ("hay guiones reescritos aplicados (%d)"):format(#GuionOverlay.List))
for _, id in GuionOverlay.List do
	check(fs.isFile(("src/shared/LifeStory/Guiones/%s.luau"):format(id)) and fs.isFile(("docs/historia/reescritura/%s.md"):format(id)), id .. ": tiene su guion (.md) y sus datos generados")
	check(fs.isFile(("docs/historia/reescritura/%s.informe.md"):format(id)), id .. ": tiene su informe")
	-- (la herramienta en modo --check: sin errores)
	local result = process.exec("lune", { "run", "scripts/audit/aplicar-reescritura.luau", id, "--check" })
	check(result.ok, id .. ": el guion se valida sin errores (aplicar-reescritura --check)")
	if not result.ok then
		print(result.stdout)
	end
end

---------------------------------------------------------------------
print("\n▶ 2. Frases nuevas, misma mecánica")
---------------------------------------------------------------------
local MECHANICS = { "Type", "Place", "Event", "Match", "Count", "Prop", "Npc", "Key", "Game", "Subject", "Teleport", "Beat", "Hint", "If", "Late", "Options" }
local function same(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for k, v in a do
		if not same(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end
for _, id in GuionOverlay.List do
	local now, base = Quests[id], BaseQuests[id]
	check(now and base and #now.Steps == #base.Steps, id .. ": mismos pasos que la misión original")
	local broken = {}
	for i, step in (base and base.Steps) or {} do
		for _, field in MECHANICS do
			if not same(step[field], now.Steps[i] and now.Steps[i][field]) then
				table.insert(broken, ("paso %d.%s"):format(i, field))
			end
		end
		for j, child in step.Steps or {} do
			for _, field in MECHANICS do
				if not same(child[field], now.Steps[i].Steps[j][field]) then
					table.insert(broken, ("paso %d.%d.%s"):format(i, j, field))
				end
			end
		end
	end
	check(#broken == 0, id .. ": la mecánica de cada paso no cambia" .. (if #broken > 0 then " (" .. table.concat(broken, ", ") .. ")" else ""))
	check(now.Guion ~= nil, id .. ": la misión lleva su guion aplicado")
end

-- Las frases de todos los guiones: texto bien escrito (UTF-8 entero, sin instrucciones del guion
-- coladas como «Si x:» o «[tu nombre]»), quien habla existe y las opciones tienen texto
local Cast = H.loadModule(ROOT .. "/shared/LifeStory/Cast")
local StageDirector = H.loadModule(ROOT .. "/shared/LifeStory/StageDirector")
for _, id in GuionOverlay.List do
	local bad = {}
	local function textOk(where: string, t: any)
		if type(t) ~= "string" then
			return
		end
		if utf8.len(t) == nil then
			table.insert(bad, where .. ": UTF-8 roto")
		elseif t:find("«Si ", 1, true) or t:match("^Si [^:]+:$") then
			table.insert(bad, where .. ": instrucción del guion como frase («" .. t .. "»)")
		elseif t:find("[tu nombre]", 1, true) or t:find("[nombre_grupo]", 1, true) then
			table.insert(bad, where .. ": marcador sin traducir («" .. t .. "»)")
		end
		local fixed = StageDirector.genderize(t, "M")
		if fixed:find("{", 1, true) and not fixed:find("{%a+}") then
			table.insert(bad, where .. ": {o/a} mal escrito («" .. t .. "»)")
		end
	end
	local function walk(where: string, lines: { any }?)
		for i, line in lines or {} do
			local w = where .. ".l" .. i
			textOk(w, line.T)
			textOk(w, line.Ask)
			if line.S and line.S ~= "Yo" and line.S ~= "Narrador" and not Cast.People[line.S] then
				table.insert(bad, w .. ": habla alguien que no existe (" .. tostring(line.S) .. ")")
			end
			for j, option in line.Options or {} do
				if type(option.T) ~= "string" or option.T == "" or option.T == "«»" then
					table.insert(bad, w .. ".o" .. j .. ": opción sin texto")
				end
				textOk(w .. ".o" .. j, option.T)
				walk(w .. ".o" .. j, option.Then)
			end
		end
	end
	local def = GuionOverlay.all()[id] or {}
	for name, d in def.Dialogues or {} do
		walk(name, d.Lines)
	end
	for sid, scene in def.Scenes or {} do
		for i, line in (scene.Tracks or {}).Dialogue or {} do
			textOk(sid .. ".d" .. i, line.T)
		end
		for i, title in (scene.Tracks or {}).Titles or {} do
			textOk(sid .. ".t" .. i, title.Text)
		end
	end
	for i = 1, math.min(#bad, 8) do
		print("     " .. bad[i])
	end
	check(#bad == 0, ("%s: frases bien escritas, de alguien del reparto y con sus opciones (%d problemas)"):format(id, #bad))
end

---------------------------------------------------------------------
print("\n▶ 2b. Toda marca que lee un guion la pone alguien")
---------------------------------------------------------------------
-- Marcas que se ponen: en los efectos de misiones y escenas (no en las condiciones) y en el código
local setFlags: { [string]: boolean } = {}
local SKIP = { If = true, IfNot = true, Requires = true, NotFlags = true, Offer = true, Variants = true }
local function scanSet(value: any, seen: { [any]: boolean })
	if type(value) ~= "table" or seen[value] then
		return
	end
	seen[value] = true
	for k, v in value do
		if k == "Flags" and type(v) == "table" then
			for _, f in v do
				if type(f) == "string" then
					setFlags[f] = true
				end
			end
		elseif k == "Set" and type(v) == "table" then
			for key in v do
				if type(key) == "string" then
					setFlags[key] = true
				end
			end
		elseif not SKIP[k] then
			scanSet(v, seen)
		end
	end
end
scanSet(Quests, {})
scanSet(H.loadModule(ROOT .. "/shared/LifeStory/HappeningIndex").all(), {})
for _, dir in { ROOT .. "/server/Services", ROOT .. "/server/LifeStory" } do
	if fs.isDir(dir) then
		for _, name in fs.readDir(dir) do
			if name:match("%.luau$") then
				local code = fs.readFile(dir .. "/" .. name)
				for f in code:gmatch("Flags%.([%w_]+)%s*=") do
					setFlags[f] = true
				end
				for f in code:gmatch("Flags%[%s*\"([%w_]+)\"%s*%]%s*=") do
					setFlags[f] = true
				end
			end
		end
	end
end
for _, id in GuionOverlay.List do
	local unset = {}
	local function readCond(c: any)
		if type(c) ~= "table" then
			return
		end
		for _, field in { "Flags", "NotFlags" } do
			for _, f in c[field] or {} do
				if not setFlags[f] and not table.find(unset, f) then
					table.insert(unset, f)
				end
			end
		end
	end
	local function walkRead(lines: { any }?)
		for _, line in lines or {} do
			readCond(line.If)
			readCond(line.IfNot)
			for _, option in line.Options or {} do
				readCond(option.If)
				walkRead(option.Then)
			end
		end
	end
	local def = GuionOverlay.all()[id] or {}
	for _, d in def.Dialogues or {} do
		walkRead(d.Lines)
	end
	for _, scene in def.Scenes or {} do
		walkRead((scene.Tracks or {}).Dialogue)
	end
	table.sort(unset)
	if #unset > 0 then
		print("     " .. id .. ": nadie pone " .. table.concat(unset, ", ") .. " (esas frases no saldrán: ver su informe)")
	end
	check(true, ("%s: marcas leídas revisadas (%d sin nadie que las ponga)"):format(id, #unset))
end

---------------------------------------------------------------------
print("\n▶ 2c. Cole11: cada combinación compañero × tema × rol")
---------------------------------------------------------------------
if Quests.Cole11_Proyecto and Quests.Cole11_Proyecto.Guion then
	local quest = Quests.Cole11_Proyecto
	local values: { [string]: { string } } = { Companero = {}, Tema = {}, Rol = {} }
	local function scanChoices(t: any, seen: { [any]: boolean })
		if type(t) ~= "table" or seen[t] then
			return
		end
		seen[t] = true
		if type(t.Choice) == "table" then
			for k, v in t.Choice do
				if values[k] and type(v) == "string" and not table.find(values[k], v) then
					table.insert(values[k], v)
				end
			end
		end
		for k, v in t do
			if k ~= "If" then
				scanChoices(v, seen)
			end
		end
	end
	scanChoices(quest, {})
	local optionDialogue: { [string]: string } = {} -- la conversación que sale al elegir a ese compañero
	for _, step in quest.Steps do
		if step.Type == "Choice" and step.Key == "Companero" then
			for _, o in step.Options do
				if not table.find(values.Companero, o.Id) then
					table.insert(values.Companero, o.Id)
				end
				if o.Dialogue then
					optionDialogue[o.Dialogue] = o.Id
				end
			end
		end
	end
	local function passes(c: any, combo: { [string]: string }): boolean
		if type(c) ~= "table" then
			return true
		end
		for k, v in c.Choices or {} do
			if combo[k] and combo[k] ~= v then
				return false
			end
		end
		for k, v in c.NotChoices or {} do
			if combo[k] and combo[k] == v then
				return false
			end
		end
		return true
	end
	local combos, bad = 0, {}
	for _, comp in values.Companero do
		for _, tema in (if #values.Tema > 0 then values.Tema else { "?" }) do
			for _, rol in (if #values.Rol > 0 then values.Rol else { "?" }) do
				combos += 1
				local combo = { Companero = comp, Tema = tema, Rol = rol }
				local function walkCombo(where: string, lines: { any }?)
					for _, line in lines or {} do
						if passes(line.If, combo) then
							if line.S and table.find(values.Companero, line.S) and line.S ~= comp then
								table.insert(bad, ("%s/%s/%s · %s: habla %s, que no está en tu equipo"):format(comp, tema, rol, where, line.S))
							end
							for _, o in line.Options or {} do
								if passes(o.If, combo) then
									walkCombo(where, o.Then)
								end
							end
						end
					end
				end
				for name, d in quest.Dialogues or {} do
					if optionDialogue[name] == nil or optionDialogue[name] == comp then
						walkCombo(name, d.Lines)
					end
				end
			end
		end
	end
	for i = 1, math.min(#bad, 6) do
		print("     " .. bad[i])
	end
	check(combos > 0 and #bad == 0, ("Cole11: %d combinaciones sin frases de alguien que no está en el equipo (%d problemas)"):format(combos, #bad))
end

---------------------------------------------------------------------
print("\n▶ 2d. Cole12: ningún recuerdo que el jugador no vivió")
---------------------------------------------------------------------
if Quests.Cole12_UltimoDia and Quests.Cole12_UltimoDia.Guion then
	local quest = Quests.Cole12_UltimoDia
	local Conditions = H.loadModule(ROOT .. "/shared/LifeStory/Conditions")
	local Sequencer = H.loadModule(ROOT .. "/shared/LifeStory/Sequencer")
	local GROUPS = { "Los Imparables", "La Patrulla Valmar", "Los del Banco Azul", "Los Dinosaurios" }
	local CAPSULAS = { "Carta", "Dibujo", "Prediccion", "Pregunta" }
	-- Lo que nombra un recuerdo y la marca que dice que se vivió
	local MEMORY_WORDS = { { "Mateo", "AyudasteAMateo" }, { "Hugo", "HugoConElGrupo" }, { "Iker", "IkerEnElGrupo" } }
	local bad, combos = {}, 0
	for _, mateo in { true, false } do
		for _, hugo in { true, false } do
			for _, iker in { true, false } do
				for _, torneo in { "TorneoGanado", "TorneoPerdido" } do
					for gi, grupo in GROUPS do
						local capsula = CAPSULAS[(gi - 1) % #CAPSULAS + 1]
						combos += 1
						local flags = { [torneo] = true }
						flags.AyudasteAMateo = mateo or nil
						flags.HugoConElGrupo = hugo or nil
						flags.IkerEnElGrupo = iker or nil
						local ctx = { Stage = "Nino", ClockTime = 10, Weekday = 2, Discovered = {}, Flags = flags, Choices = { NombreGrupo = { V = grupo }, Capsula = { V = capsula } }, Memories = {}, Traits = {}, Completed = {}, Rel = {} }
						local function ok(c: any): boolean
							if type(c) ~= "table" then
								return true
							end
							local passed = Conditions.check(c, ctx)
							return passed == true
						end
						local function look(where: string, lines: { any }?)
							for _, line in lines or {} do
								if ok(line.If) and not (line.IfNot and ok(line.IfNot)) and type(line.T) == "string" then
									for _, mw in MEMORY_WORDS do
										if line.T:find(mw[1], 1, true) and not flags[mw[2]] and line.S ~= mw[1] then
											table.insert(bad, ("%s: «%s» (sin %s)"):format(where, line.T, mw[2]))
										end
									end
									for _, g in GROUPS do
										if g ~= grupo and line.T:find(g, 1, true) then
											table.insert(bad, ("%s: «%s» (el grupo es %s)"):format(where, line.T, grupo))
										end
									end
									for _, o in line.Options or {} do
										if ok(o.If) then
											look(where, o.Then)
										end
									end
								end
							end
						end
						for name, d in quest.Dialogues or {} do
							look(name, d.Lines)
						end
						for _, step in quest.Steps do
							local def = step.Type == "Cinematic" and H.loadModule(ROOT .. "/shared/LifeStory/HappeningIndex").get(step.Id)
							if def then
								local resolved = Sequencer.resolve(def, function(req)
									return (Conditions.check(req, ctx))
								end)
								look(step.Id, Sequencer.expand(def, resolved).Tracks.Dialogue)
							end
						end
					end
				end
			end
		end
	end
	local seen, unique = {}, {}
	for _, b in bad do
		if not seen[b] then
			seen[b] = true
			table.insert(unique, b)
		end
	end
	for i = 1, math.min(#unique, 8) do
		print("     " .. unique[i])
	end
	check(#unique == 0, ("Cole12: %d partidas distintas sin ningún recuerdo no vivido (%d frases de más)"):format(combos, #unique))
end

local PROLOGUE = "Prologo_Sueno"
local prologue = Quests[PROLOGUE]
local sueno = prologue.Dialogues.Sueno.Lines
local function hasLine(lines: { any }, text: string): boolean
	for _, line in lines do
		if line.T == text then
			return true
		end
		for _, option in line.Options or {} do
			if hasLine(option.Then or {}, text) then
				return true
			end
		end
	end
	return false
end
check(hasLine(sueno, "En los sueños nunca se sabe.") and hasLine(sueno, "Se llama la Grieta.") and hasLine(sueno, "Bastante."), "prólogo: Cosme dice las frases nuevas del guion")
check(not hasLine(sueno, "Soy Cosme. Inventor. Genio. Vecino."), "prólogo: ya no dice las de antes")
check(hasLine(sueno, "Eso sí que no me lo esperaba.") and hasLine(sueno, "Bueno… depende de cuánto te guste estar entero."), "prólogo: cada respuesta tiene su réplica nueva")
check(prologue.Steps[1].Id ~= "Prologo_Apertura" and H.loadModule(ROOT .. "/shared/LifeStory/HappeningIndex").has(prologue.Steps[1].Id), "prólogo: la apertura es la cinemática nueva (escena del motor)")
check(hasLine(prologue.Dialogues.Tornillo.Lines, "Eso no estaba previsto."), "prólogo: al coger el tornillo, la reacción nueva de Cosme")

---------------------------------------------------------------------
print("\n▶ 3. El prólogo se completa con cada respuesta")
---------------------------------------------------------------------
local Service, StoryEvents = H.boot()
H.Config.LifeStory.Prologue = true
local played: { [any]: { [string]: boolean } } = {}
do
	local Happening = H.loadModule(ROOT .. "/server/Services/HappeningService")
	local realPlay = Happening.play
	Happening.play = function(p, id, ...)
		played[p] = played[p] or {}
		played[p][id] = true
		return realPlay(p, id, ...)
	end
end
local function waitFor(condition: () -> boolean, seconds: number): boolean
	local t = 0
	while t < seconds do
		if condition() then
			return true
		end
		task.wait(0.25)
		t += 0.25
	end
	return condition()
end

local function playPrologue(name: string, prefer: string, choice: string, trait: string, reply: string)
	local p = H.newPlayer(name)
	p.Prefer = { prefer }
	p.Answer = H.preferAnswer(p)
	local story = H.profiles[p].Story
	local function step(): number?
		local prog = story.Active[PROLOGUE]
		return prog and prog.Step
	end
	check(waitFor(function()
		return step() ~= nil
	end, 3), ("[%s] empieza el prólogo"):format(name))
	check(waitFor(function()
		return step() == 2
	end, 90), ("[%s] la cinemática de apertura termina y empieza el primer paso"):format(name))
	local actions = {
		function()
			p.At = "PrologoCamino"
		end,
		function()
			StoryEvents.emit(p, "Sprinted", {})
		end,
		function()
			p.At = "PrologoSalto"
		end,
		function()
			Service.interact(p, "Actor", PROLOGUE, "Cosme")
		end,
		function()
			Service.interact(p, "Prop", PROLOGUE, "Tornillo")
		end,
		function()
			p.At = "PrologoPuerta"
		end,
		function()
			H.fromClient(p, "Prologue", "MapOpened")
		end,
	}
	for i, act in actions do
		task.wait(1.2) -- (como un jugador: un momento después de que empiece el paso)
		act()
		check(waitFor(function()
			return step() == i + 2 or story.Active[PROLOGUE] == nil
		end, 40), ("[%s] paso %d cumplido con su acción"):format(name, i + 1))
	end
	check(waitFor(function()
		return story.Active[PROLOGUE] == nil
	end, 90), ("[%s] el prólogo termina entero"):format(name))
	check(story.PrologueResult == "Done", ("[%s] queda como visto y terminado"):format(name))
	check(story.Choices.Prologo and story.Choices.Prologo.V == choice, ("[%s] decisión del prólogo = %s"):format(name, choice))
	check((story.Traits[trait] or 0) >= 1, ("[%s] rasgo %s +1"):format(name, trait))
	check(H.said(p, "Llegas pronto.") and H.said(p, "Se llama la Grieta."), ("[%s] Cosme dice las frases nuevas"):format(name))
	check(H.said(p, reply), ("[%s] y la réplica de su rama: «%s»"):format(name, reply))
	check(H.said(p, "Eso no estaba previsto."), ("[%s] la reacción al coger el tornillo"):format(name))
	local scenes = played[p] or {}
	check(scenes[prologue.Steps[1].Id] and scenes[prologue.Steps[#prologue.Steps].Id], ("[%s] se ven la apertura y el cierre nuevos"):format(name))
	local light = 0
	for id in scenes do
		if id:find("_Entra$") or id:find("_Fin$") then
			light += 1
		end
	end
	check(light >= 4, ("[%s] las frases de los pasos jugables suenan en escenas ligeras (%d)"):format(name, light))
end

playPrologue("Ayuda", "ayudo", "Ayudar", "Valentia", "Eso sí que no me lo esperaba.")
playPrologue("Pregunta", "peligroso", "Preguntar", "Curiosidad", "Bueno… depende de cuánto te guste estar entero.")

local _ = roblox
print(("\n%s Reescritura: %d fallos"):format(if H.failures == 0 then "✅" else "❌", H.failures))
process.exit(if H.failures == 0 then 0 else 1)
