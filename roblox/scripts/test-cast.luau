-- Prueba del REPARTO (Cast.luau, paquete P9).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-cast.luau
--
-- Comprueba:
--   1. Cada personaje que usan las misiones y las escenas (quién habla, Npc, relaciones) existe en el reparto.
--   2. Cada personaje tiene los campos de siempre (Name, Voice, Skin, Shirt, Pants, Bio).
--   3. El reparto principal (Cast.Principales) tiene ficha completa: personalidad, forma de hablar con
--      muletillas, emociones, relaciones (con gente que existe), motivación y arco por etapas válidas.
--   4. Actuar: emociones de ActorMoods y gestos de Emotion que existen; números en rango.
--   5. Edades: etapas válidas; los compañeros crecen (0,65 → 0,85 → 1) y pierden la mochila de mayores;
--      Cast.atStage no cambia la ficha original; Cast.nameOf sigue igual.
--   6. El validador no da errores de reparto.

local process = require("@lune/process")
local H = require("./lib/StoryHarness")

local function load(name: string)
	return H.loadModule(H.ROOT .. "/shared/LifeStory/" .. name)
end

local Cast = load("Cast")
local Stages = load("Stages")
local ActorMoods = load("ActorMoods")
local Emotion = load("Emotion")
local MissionIndex = load("MissionIndex")
local HappeningIndex = load("HappeningIndex")
local People = Cast.People

local failures = 0
local checks = 0
local function check(ok: any, msg: string)
	checks += 1
	if not ok then
		failures += 1
		print("  ❌ " .. msg)
	end
end

local SPECIAL = { Yo = true, Narrador = true, Player = true, Todos = true, Speaker = true }

-- 1. Ids que usan las misiones y las escenas ----------------------------------------------------------
print("1. Ids del reparto en misiones y escenas")
local used: { [string]: string } = {}
local function walk(node: any, where: string, allowed: { [string]: boolean }, seen: { [any]: boolean })
	if type(node) ~= "table" or seen[node] then
		return
	end
	seen[node] = true
	for key, value in node do
		if (key == "S" or key == "Npc" or key == "Speaker") and type(value) == "string" then
			if not SPECIAL[value] and not allowed[value] then
				used[value] = used[value] or where
				check(People[value] ~= nil, ("%s: '%s' no está en el reparto (%s)"):format(where, value, key))
			end
		elseif (key == "Rel" or key == "RelBelow") and type(value) == "table" then
			for npc in value do
				if type(npc) == "string" then
					used[npc] = used[npc] or where
					check(People[npc] ~= nil, ("%s: relación con '%s', que no está en el reparto"):format(where, npc))
				end
			end
		end
		if type(value) == "table" then
			walk(value, where, allowed, seen)
		end
	end
end

local quests = 0
for _, entry in MissionIndex do
	local list = if entry.Id then { entry } else entry
	for _, quest in list do
		quests += 1
		walk(quest, tostring(quest.Id), {}, {})
	end
end

-- En una escena, «quién habla» puede ser la clave de un actor o criatura de esa escena
local scenes = 0
for id, def in HappeningIndex.all() do
	scenes += 1
	local allowed: { [string]: boolean } = {}
	local actors = def.Actors or (def.Tracks and def.Tracks.Actors)
	if type(actors) == "table" then
		for key, spec in actors do
			if type(key) == "string" then
				allowed[key] = true
			end
			if type(spec) == "table" then
				for _, field in { "Key", "Id", "As" } do
					if type(spec[field]) == "string" then
						allowed[spec[field]] = true
					end
				end
			end
		end
	end
	-- y las criaturas o actores que la escena crea con Key = "…"
	local function keys(node: any, seen: { [any]: boolean })
		if type(node) ~= "table" or seen[node] then
			return
		end
		seen[node] = true
		if type(node.Key) == "string" then
			allowed[node.Key] = true
		end
		for _, value in node do
			keys(value, seen)
		end
	end
	keys(def, {})
	walk(def, "escena " .. id, allowed, {})
end
local count = 0
for _ in used do
	count += 1
end
print(("   %d misiones, %d escenas, %d personajes distintos usados"):format(quests, scenes, count))
check(quests > 50 and count > 30, "se esperaban muchas misiones y personajes")

-- 2. Campos de siempre -----------------------------------------------------------------------------
print("2. Campos de siempre")
for id, p in People do
	check(type(p.Name) == "string" and p.Name ~= "", id .. ": falta Name")
	check(type(p.Voice) == "string", id .. ": falta Voice")
	check(typeof(p.Skin) == "Color3" and typeof(p.Shirt) == "Color3" and typeof(p.Pants) == "Color3", id .. ": faltan colores")
	check(type(p.Bio) == "string", id .. ": Bio debe seguir siendo texto")
end
check(Cast.nameOf("Familia", { FamilyKey = "NPC.PAPA" }) == "NPC.PAPA", "nameOf: la familia depende de la casa")
check(Cast.nameOf("Familia", nil) == "NPC.MAMA", "nameOf: Familia por defecto")
check(Cast.nameOf("Nadie", nil) == "Nadie", "nameOf: id desconocido")

-- 3. Fichas del reparto principal -------------------------------------------------------------------
print("3. Fichas del reparto principal")
local function text(v: any): boolean
	return type(v) == "string" and #v >= 8
end
check(#Cast.Principales >= 20, "el reparto principal debería tener al menos 20 personajes")
for _, id in Cast.Principales do
	local p = People[id]
	check(p ~= nil, id .. ": está en Principales pero no en el reparto")
	local f = p and p.Perfil
	check(f ~= nil, id .. ": sin Perfil")
	if f then
		check(text(f.Personalidad), id .. ": falta Personalidad")
		check(type(f.Habla) == "table" and text(f.Habla.Vocabulario) and text(f.Habla.Ritmo), id .. ": falta Habla (Vocabulario, Ritmo)")
		check(type(f.Habla) == "table" and type(f.Habla.Muletillas) == "table" and #f.Habla.Muletillas >= 2, id .. ": pocas muletillas")
		check(text(f.Emociones), id .. ": falta Emociones")
		check(text(f.Motivacion), id .. ": falta Motivacion")
		local rels = 0
		for other, how in f.Relaciones or {} do
			rels += 1
			check(People[other] ~= nil, ("%s: relación con '%s', que no existe"):format(id, other))
			check(text(how), ("%s: relación con %s sin describir"):format(id, other))
		end
		check(rels >= 1, id .. ": sin Relaciones")
		local arcs = 0
		for stage, how in f.Arco or {} do
			arcs += 1
			check(Stages.isValid(stage), ("%s: Arco con etapa desconocida '%s'"):format(id, stage))
			check(text(how), ("%s: Arco.%s vacío"):format(id, stage))
		end
		check(arcs >= 1, id .. ": sin Arco")
		local full = Cast.bioText(id)
		check(full:find(f.Habla.Muletillas[1], 1, true) ~= nil, id .. ": bioText no incluye las muletillas")
	end
	check(p and p.Actuar and p.Actuar.Mood, id .. ": el reparto principal necesita Actuar.Mood")
end
check(People.Familia.Perfil and #People.Familia.Perfil.Habla.Muletillas >= 4, "Familia: perfil propio con frases recurrentes (W-06)")

-- 4. Actuar ---------------------------------------------------------------------------------------
print("4. Actuar (emociones y gestos)")
local GAZES = { Down = true, Avoid = true, Around = true, Hold = true }
for id, p in People do
	local a = p.Actuar
	if a then
		if a.Mood then
			check(ActorMoods.List[a.Mood] ~= nil or ActorMoods.Alias[a.Mood] ~= nil, ("%s: Mood '%s' no existe en ActorMoods"):format(id, a.Mood))
		end
		check(a.Gaze == nil or GAZES[a.Gaze], id .. ": Gaze desconocido")
		check(a.Fidget == nil or (a.Fidget >= 0 and a.Fidget <= 1), id .. ": Fidget fuera de 0..1")
		check(a.Tempo == nil or (a.Tempo >= 0.5 and a.Tempo <= 1.6), id .. ": Tempo fuera de rango")
		check(a.Open == nil or (a.Open >= -1 and a.Open <= 1), id .. ": Open fuera de -1..1")
		check(a.Head == nil or math.abs(a.Head) <= 0.3, id .. ": Head demasiado grande")
		for _, g in a.Gestos or {} do
			check(Emotion.valid(g), ("%s: gesto desconocido '%s'"):format(id, g))
		end
	end
end
-- Los nerviosos se mueven más que los tranquilos
check((Cast.acting("Mateo").Fidget or 0) > (Cast.acting("Abu").Fidget or 0), "Mateo (nervioso) debería moverse más que Abu")
check(Cast.defaultMood("Mateo") == "Nervous", "Mateo: emoción de base Nervous")
check(Cast.defaultMood("Vecino") == nil and next(Cast.acting("Vecino")) == nil, "sin Actuar: valores por defecto")

-- 5. Edades ---------------------------------------------------------------------------------------
print("5. Edades (montajes de etapa)")
for id, p in People do
	for stage, edad in p.Edades or {} do
		check(Stages.isValid(stage), ("%s: Edades con etapa desconocida '%s'"):format(id, stage))
		check(edad.Scale == nil or (edad.Scale > 0.3 and edad.Scale <= 1.2), ("%s: escala rara en %s"):format(id, stage))
	end
end
for _, id in { "Nico", "Sara", "Omar", "Mateo", "Bruno", "Hugo", "Leire" } do
	check(People[id].Edades ~= nil, id .. ": crece contigo y necesita Edades")
	check(Cast.scaleAt(id, "Nino") == 0.65, id .. ": de niño, 0,65")
	check(Cast.scaleAt(id, "Adolescente") >= 0.85 and Cast.scaleAt(id, "Adolescente") < 1, id .. ": de adolescente, ~0,85")
	check(Cast.scaleAt(id, "Adulto") == 1, id .. ": de adulto, 1")
	local adult = Cast.atStage(id, "Adulto")
	check(adult and adult.Backpack == nil, id .. ": de adulto, sin mochila")
	check(adult and adult.Age == nil, id .. ": de adulto, Age nil (anda como adulto)")
	check(Cast.atStage(id, "Nino").Age == "Nino", id .. ": de niño, Age = Nino")
end
check(People.Nico.Backpack ~= nil, "atStage no debe tocar la ficha original")
check(Cast.atStage("Bruno", "Adulto").Shirt ~= People.Bruno.Shirt, "Bruno adulto lleva uniforme")
check(Cast.scaleAt("Dani", "Adolescente") == 0.65, "Dani va una etapa por detrás")
-- Sin Edades: la misma regla que SceneService
check(Cast.scaleAt("Alba", "Adolescente") == 0.85 and Cast.scaleAt("Alba", "Nino") == 0.65, "Kid sin Edades: regla de SceneService")
check(Cast.scaleAt("Veterano", "Nino") == 0.85 and Cast.scaleAt("Lucia", "Nino") == 1, "Teen y adulto")
check(Cast.atStage("Abu", "Adulto").Age == "Mayor", "Old: Age Mayor")
check(Cast.atStage("Nadie", "Nino") == nil, "atStage de un id desconocido = nil")

-- 6. El validador ----------------------------------------------------------------------------------
print("6. Validador")
local report = load("Validate").report()
for _, e in report.Errors do
	local castProblem = e:find("reparto", 1, true) or e:find("personaje que no existe", 1, true)
	check(not castProblem, "validador: " .. e)
end

print(("\n%d comprobaciones, %d fallos"):format(checks, failures))
process.exit(if failures == 0 then 0 else 1)
