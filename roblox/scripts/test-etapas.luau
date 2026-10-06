-- Prueba de P7 · MONTAJES Y FINALES (Lune, fuera de Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-etapas.luau
--
-- Comprueba (docs/historia/auditoria-narrativa-cinematica.md §6.3, C-13, C-18, M-06, M-07):
--   1. Las escenas de shared/LifeStory/Happenings/Etapas existen, están en HappeningIndex (grupo Etapas)
--      y se validan sin errores; los nombres viejos (Nino_AInstituto, Adol_Selectividad) son el mismo
--      montaje y ya no hay un vuelo viejo con ese nombre en Cinematics.luau.
--   2. Cada montaje tiene sus cuatro tiempos (cierre íntimo, recuerdos, el mundo cambia, llegada), dura
--      lo que pide el diseño y NO enseña al jugador hasta la llegada (la edad cambia fuera de plano).
--   3. Las fotos vivas: cada foto tiene plan B; con una vida vacía sale el plan B y con una vida llena la
--      primera candidata; nunca salen dos a la vez (un solo plano por foto).
--   4. Continuidad: las escenas leen las marcas, recuerdos y decisiones de antes (nombre del grupo,
--      promesa a Abu, promesa adulta, Mateo, Hugo, Leire, el club…), y todas existen en las misiones.
--   5. Lo conectan las misiones y los capítulos: cada Transition con SetStage lleva su montaje (y la etapa
--      del montaje es la misma), Adu03 cambia de etapa con un paso Transition, Adulto_MirarAtras lanza
--      el final de la vida y cada capítulo tiene su cabecera y su final.
--   6. El final de la vida: la familia (una sola variante), el álbum (una foto por etapa) y la gente que
--      conociste llega andando.

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")

local check = L.check

local Sequencer = L.load("src/shared/LifeStory/Sequencer")
local HappeningIndex = L.load("src/shared/LifeStory/HappeningIndex")
local Locations = L.load("src/shared/LifeStory/Locations")
local Cast = L.load("src/shared/LifeStory/Cast")
local Catalog = L.load("src/shared/StoryFxCatalog")
local SkyMoods = L.load("src/shared/SkyMoods")
local ActorMoods = L.load("src/shared/LifeStory/ActorMoods")
local StoryCreatures = L.load("src/shared/LifeStory/StoryCreatures")
local Conditions = L.load("src/shared/LifeStory/Conditions")
local Cinematics = L.load("src/shared/LifeStory/Cinematics")
local Chapters = L.load("src/shared/LifeStory/Chapters")
local Quests = L.load("src/shared/LifeStory/Quests")

local MONTAGES = { "Montaje_Bebe_Nino", "Montaje_Nino_Adolescente", "Montaje_Adolescente_Joven", "Montaje_Joven_Adulto" }
local ALL = { "Montaje_Bebe_Nino", "Montaje_Nino_Adolescente", "Montaje_Adolescente_Joven", "Montaje_Joven_Adulto", "Vida_MirarAtras", "Nino_AInstituto", "Adol_Selectividad" }

---------------------------------------------------------------------
print("1. Las escenas existen, están registradas y se validan")
---------------------------------------------------------------------
check(table.find(HappeningIndex.Groups, "Etapas") ~= nil, "el grupo Etapas está en HappeningIndex")
local ctx = {
	Fx = Catalog.names(),
	SkyMoods = SkyMoods.names(),
	Moods = ActorMoods.names(),
	Creatures = StoryCreatures.names(),
	Places = Locations.Places,
	Zones = Locations.Zones,
	Cast = Cast.People,
}
for _, id in ALL do
	local def = HappeningIndex.get(id)
	check(def ~= nil and HappeningIndex.groupOf(id) == "Etapas", ("%s existe (grupo Etapas)"):format(id))
	if def then
		local errors = Sequencer.validate(id, def, ctx)
		for _, e in errors do
			print("     " .. e)
		end
		check(#errors == 0, ("%s sin errores"):format(id))
		check(Cinematics[id] == nil, ("%s no choca con una cinemática vieja"):format(id))
		check(def.Skippable == true, ("%s se puede saltar"):format(id))
	end
end
check(HappeningIndex.get("Nino_AInstituto") == HappeningIndex.get("Montaje_Nino_Adolescente"), "Nino_AInstituto es el montaje niño → adolescente")
check(HappeningIndex.get("Adol_Selectividad") == HappeningIndex.get("Montaje_Adolescente_Joven"), "Adol_Selectividad es el montaje adolescente → joven")
check(Cinematics.Bebe_AnosDespues == nil, "el vuelo viejo «Han pasado varios años» ya no está")

---------------------------------------------------------------------
print("2. Los cuatro tiempos de cada montaje, y la edad cambia fuera de plano")
---------------------------------------------------------------------
local BEATS = { { 0, 7.5, "cierre íntimo" }, { 7.5, 21.3, "recuerdos" }, { 21.3, 29.5, "el mundo cambia" }, { 29.5, 36, "llegada" } }
local function anchorsOf(shot): { string }
	local out = {}
	for _, field in { "From", "To", "Fixed", "Look", "LookTo" } do
		local p = shot[field]
		if type(p) == "table" and type(p[1]) == "string" then
			table.insert(out, p[1])
		end
	end
	if type(shot.Shot) == "string" then
		for name in shot.Shot:gmatch("[^:,>|]+") do
			table.insert(out, name)
		end
	end
	return out
end
for _, id in MONTAGES do
	local def = HappeningIndex.get(id)
	local timeline = Sequencer.compile(id, def)
	check(timeline.Duration >= 25 and timeline.Duration <= 40, ("%s dura entre 25 y 40 s (%.1f)"):format(id, timeline.Duration))
	check(type(def.Montaje) == "table" and def.Montaje.From and def.Montaje.To, ("%s dice de qué etapa a qué etapa va"):format(id))
	for _, beat in BEATS do
		local shots, lines = 0, 0
		for _, e in timeline.Events do
			if e.At >= beat[1] - 1e-6 and e.At < beat[2] - 1e-6 then
				if e.Track == "Camera" then
					shots += 1
				elseif e.Track == "Lines" or e.Track == "Titles" then
					lines += 1
				end
			end
		end
		check(shots > 0 and lines > 0, ("%s: tiempo «%s» con plano y texto"):format(id, beat[3]))
	end
	-- Hasta la llegada no se ve al jugador (ni "Player" ni "Yo" en ningún plano)
	local seen = false
	local arrival = false
	for _, shot in def.Tracks.Camera do
		for _, name in anchorsOf(shot) do
			if name == "Player" or name == "Yo" then
				if shot.At < 29.5 then
					seen = true
				else
					arrival = true
				end
			end
		end
	end
	check(not seen and arrival, ("%s: el jugador solo sale en la llegada (crece fuera de plano)"):format(id))
	-- Música: íntima al empezar, «Pasan los años» en los recuerdos, otra pieza al cambiar el mundo
	local intimate, years, newTheme = false, false, false
	for _, m in def.Tracks.Music do
		intimate = intimate or (m.At == 0 and m.Intensity == "Intima")
		years = years or (m.At == 7.5 and m.Play == "PasanLosAnos")
		newTheme = newTheme or (math.abs(m.At - 21.3) < 0.01 and (m.Play ~= nil or m.Intensity ~= nil))
	end
	check(intimate and years and newTheme, ("%s: la música va de íntima a «Pasan los años» y sube al cambiar el mundo"):format(id))
	-- Luz de recuerdo en las fotos, que se quita al cambiar el mundo
	local memoryLight, cleared = false, false
	for _, l in def.Tracks.Light do
		memoryLight = memoryLight or l.Preset == "Recuerdo"
		cleared = cleared or (l.Preset == false and l.At > 20)
	end
	check(memoryLight and cleared, ("%s: luz de recuerdo en las fotos"):format(id))
	-- Entran andando en el mundo nuevo
	local walkers = 0
	for _, a in def.Tracks.Actors do
		if a.Enter and a.Enter.Walk == true and a.At >= 20 then
			walkers += 1
		end
	end
	check(walkers >= 2, ("%s: en el mundo nuevo la gente entra andando (%d)"):format(id, walkers))
end

---------------------------------------------------------------------
print("3. Fotos vivas: plan B, prioridad y una sola foto a la vez")
---------------------------------------------------------------------
-- Una partida de mentira para Conditions
local function life(facts)
	local choices = {}
	for k, v in facts.Choices or {} do
		choices[k] = { V = v }
	end
	local function set(list)
		local out = {}
		for _, x in list or {} do
			out[x] = 1
		end
		return out
	end
	local c = {
		Stage = "Adulto",
		ClockTime = 12,
		Weekday = 1,
		Completed = set(facts.Completed),
		Flags = set(facts.Flags),
		Choices = choices,
		Discovered = {},
		Memories = set(facts.Memories),
		Rel = {},
		Traits = {},
	}
	return function(req)
		return (Conditions.check(req, c))
	end
end

local EMPTY = life({})
local FULL = life({
	Completed = { "Bebe_AprendeACaminar", "Bebe_ExploraLaCasa" },
	Flags = { "AyudasteAMateo", "HugoConElGrupo", "ConocesALeire", "RayoCambia", "VaALaUniversidad", "SecretoLucia", "CapsulaDelTiempo" },
	Memories = { "PrimerGrupo", "PrimerTorneo", "LaNoche", "PrimerClub", "ElRumor", "AtardecerConAbu", "Graduacion", "ElCruce", "ElReencuentro" },
	Choices = { NombreGrupo = "La Patrulla Valmar", Club = "Fotografia", PromesaAbu = "Volver", PromesaAdulta = "Hijos", Promesa = "Juntos", AdiosBruno = "DeCero" },
})

local function photoShots(id, check_)
	local def = HappeningIndex.get(id)
	local expanded = Sequencer.expand(def, Sequencer.resolve(def, check_))
	local bySlot = {}
	for _, photo in def.Photos do
		bySlot[photo.Slot] = bySlot[photo.Slot] or { Candidates = 0 }
		bySlot[photo.Slot].Candidates += 1
	end
	return def, expanded, bySlot
end

for _, id in { "Montaje_Bebe_Nino", "Montaje_Nino_Adolescente", "Montaje_Adolescente_Joven", "Montaje_Joven_Adulto", "Vida_MirarAtras" } do
	local def = HappeningIndex.get(id)
	check(type(def.Photos) == "table" and #def.Photos >= 3, ("%s tiene fotos vivas"):format(id))
	-- Cada foto: la última candidata no tiene condición (plan B)
	local last = {}
	for _, photo in def.Photos do
		last[photo.Slot] = photo
	end
	local allFallback = true
	for _, photo in last do
		allFallback = allFallback and photo.If == nil
	end
	check(allFallback, ("%s: cada foto tiene plan B"):format(id))
	for label, judge in { vacia = EMPTY, llena = FULL } do
		local _, expanded = photoShots(id, judge)
		-- Un solo plano por foto (los planos de las fotos empiezan a la vez que su foto)
		local starts = {}
		for _, photo in def.Photos do
			starts[photo.Slot] = true
		end
		local firstAt = math.huge
		for _, photo in def.Photos do
			for _, shot in def.Tracks.Camera do
				if shot.Cut == "Dip" and shot.Fixed and shot.Fixed[1] == "P_" .. photo.Place then
					firstAt = math.min(firstAt, shot.At)
				end
			end
		end
		local perSlot = {}
		for _, shot in expanded.Tracks.Camera do
			if shot.Fixed and type(shot.Fixed[1]) == "string" and shot.Fixed[1]:sub(1, 2) == "P_" then
				local slot = math.floor((shot.At - firstAt) / 4.6 + 0.5) + 1
				perSlot[slot] = (perSlot[slot] or 0) + 1
			end
		end
		local ok = true
		for slot in starts do
			if perSlot[slot] ~= 1 then
				ok = false
				print(("     %s (%s): la foto %d tiene %d planos"):format(id, label, slot, perSlot[slot] or 0))
			end
		end
		check(ok, ("%s (vida %s): una sola foto en cada hueco"):format(id, label))
	end
	-- Vida vacía → plan B en todas; vida llena → la primera candidata
	local function chosen(judge)
		local out = {}
		for _, photo in def.Photos do
			if out[photo.Slot] == nil and (photo.Gate == nil or judge(photo.Gate)) then
				out[photo.Slot] = photo.Candidate
			end
		end
		return out
	end
	local empty, full = chosen(EMPTY), chosen(FULL)
	local emptyOk, fullOk = true, true
	for slot, photo in last do
		emptyOk = emptyOk and empty[slot] == photo.Candidate
		fullOk = fullOk and full[slot] == 1
	end
	check(emptyOk, ("%s: sin recuerdos, salen los planes B"):format(id))
	check(fullOk, ("%s: con una vida llena, sale lo más tuyo (la primera de cada foto)"):format(id))
end

-- El nombre del grupo sale en el rótulo de la foto del grupo
do
	local def = HappeningIndex.get("Montaje_Nino_Adolescente")
	local named = Sequencer.expand(def, Sequencer.resolve(def, FULL))
	local found, others = false, false
	for _, t in named.Tracks.Titles do
		if t.Text == "«La Patrulla Valmar»" then
			found = true
		elseif t.Text == "«Los Imparables»" then
			others = true
		end
	end
	check(found and not others, "la foto del grupo dice su nombre (el que elegiste, y solo ese)")
	local club = Sequencer.expand(HappeningIndex.get("Montaje_Adolescente_Joven"), Sequencer.resolve(HappeningIndex.get("Montaje_Adolescente_Joven"), FULL))
	local leire, alex = false, false
	for _, a in club.Tracks.Actors do
		if a.Spawn and a.Spawn.Npc == "Leire" then
			leire = true
		elseif a.Spawn and a.Spawn.Npc == "Alex" then
			alex = true
		end
	end
	check(leire and not alex, "la foto del club es la de tu club (Fotografía: Leire)")
end

---------------------------------------------------------------------
print("4. Continuidad: las escenas leen lo que hiciste antes")
---------------------------------------------------------------------
local read = { Flags = {}, Memories = {}, Choices = {}, Completed = {} }
local function collect(node, seen)
	if type(node) ~= "table" or seen[node] then
		return
	end
	seen[node] = true
	for k, v in node do
		if (k == "If" or k == "IfNot" or k == "Gate") and type(v) == "table" then
			for kind, value in v do
				local base = (kind :: string):gsub("^Not", "")
				if read[base] then
					for a, b in value do
						if type(a) == "number" then
							read[base][b] = true
						else
							read[base][a .. "=" .. tostring(b)] = true
						end
					end
				end
			end
		end
		collect(v, seen)
	end
end
for _, id in ALL do
	collect(HappeningIndex.get(id), {})
end
local WANT = {
	Choices = { "NombreGrupo=Los Imparables", "NombreGrupo=La Patrulla Valmar", "NombreGrupo=Los del Banco Azul", "NombreGrupo=Los Dinosaurios", "PromesaAbu=Volver", "PromesaAbu=CosasBonitas", "PromesaAbu=Familia", "PromesaAdulta=Hijos", "PromesaAdulta=Viaje", "PromesaAdulta=Siempre", "Promesa=Juntos", "Club=Fotografia", "Club=Baloncesto", "AdiosBruno=DeCero" },
	Flags = { "AyudasteAMateo", "HugoConElGrupo", "ConocesALeire", "SecretoLucia", "CapsulaDelTiempo", "RayoCambia", "VaALaUniversidad", "EmpiezaATrabajar", "TienePareja" },
	Memories = { "PrimerGrupo", "PrimerTorneo", "PrimeraExcursion", "ProyectoFinal", "Detective", "LaNoche", "PrimerSueldo", "PrimerClub", "ElRumor", "ElCruce", "AtardecerConAbu", "Graduacion", "PrimerContrato", "ElReencuentro" },
	Completed = { "Bebe_AprendeACaminar", "Bebe_ExploraLaCasa" },
}
for kind, list in WANT do
	local missing = {}
	for _, name in list do
		if not read[kind][name] then
			table.insert(missing, name)
		end
	end
	check(#missing == 0, ("continuidad (%s): %s"):format(kind, if #missing == 0 then "todo se lee" else "falta " .. table.concat(missing, ", ")))
end
-- Y lo que se lee existe de verdad (lo escribe alguna misión): sin erratas
local source = ""
for _, dir in { "src/shared/LifeStory/Misiones", "src/shared/LifeStory" } do
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isFile(path) and name:match("%.luau$") then
			source ..= fs.readFile(path)
		end
	end
end
local typos = {}
for kind, names in read do
	for name in names do
		local plain = name:match("^([^=]+)=") or name
		local value = name:match("=(.+)$")
		if kind == "Completed" then
			if not Quests[plain] then
				table.insert(typos, name)
			end
		elseif not source:find('"' .. plain .. '"', 1, true) and not source:find(plain .. " = ", 1, true) then
			table.insert(typos, name)
		elseif value and not source:find('"' .. value .. '"', 1, true) then
			table.insert(typos, name)
		end
	end
end
table.sort(typos)
check(#typos == 0, "todo lo que se lee lo escribe alguna misión" .. (if #typos > 0 then " (no se encuentra: " .. table.concat(typos, ", ") .. ")" else ""))

---------------------------------------------------------------------
print("5. Lo conectan las misiones y los capítulos")
---------------------------------------------------------------------
local transitions = {}
for questId, quest in Quests do
	for _, step in quest.Steps or {} do
		-- (Nino_TuBarrio, el puente viejo desactivado, sigue con su vuelo de Cinematics.luau)
		if step.Type == "Transition" and step.SetStage and step.Cinematic and not Cinematics[step.Cinematic] then
			local def = HappeningIndex.get(step.Cinematic)
			table.insert(transitions, questId)
			check(def ~= nil and def.Montaje ~= nil and def.Montaje.To == step.SetStage, ("%s: el cambio a %s lleva su montaje (%s)"):format(questId, step.SetStage, step.Cinematic))
		end
	end
end
local function transitionOf(questId)
	for _, step in (Quests[questId] or {}).Steps or {} do
		if step.Type == "Transition" and step.SetStage then
			return step
		end
	end
	return nil
end
check((transitionOf("Bebe_HoraDeSalir") or {}).Cinematic == "Montaje_Bebe_Nino", "Bebé → niño: Montaje_Bebe_Nino")
check(HappeningIndex.get((transitionOf("Cole12_UltimoDia") or {}).Cinematic) == HappeningIndex.get("Montaje_Nino_Adolescente"), "Niño → adolescente (Cole12): el montaje")
check(HappeningIndex.get((transitionOf("Ins06_LaGranDecision") or {}).Cinematic) == HappeningIndex.get("Montaje_Adolescente_Joven"), "Adolescente → joven (Ins06): el montaje")
local adu03 = transitionOf("Adu03_Reencuentro")
check(adu03 ~= nil and adu03.SetStage == "Adulto" and adu03.Cinematic == "Montaje_Joven_Adulto", "Adulto joven → adulto (Adu03): un paso Transition con el montaje, no solo un premio (M-06)")
local steps = Quests.Adulto_MirarAtras.Steps
local hasFinal = false
for _, step in steps do
	hasFinal = hasFinal or (step.Type == "Cinematic" and step.Id == "Vida_MirarAtras")
end
check(hasFinal and steps[1].Type == "Reach" and steps[1].Place == "CasaFamiliar", "Mirar atrás: vuelves a casa y se ve el final de la vida (M-07)")
-- Cada capítulo de la vida jugada: cabecera (Intro) y final (Outro o montaje de su última misión)
local MONTAGE_END = { Bebe_PrimerosPasos = true, Nino_ElColegio = true, Adolescente_Instituto = true }
for id, chapter in Chapters do
	if chapter.Enabled then
		check(chapter.IntroCinematic ~= nil and Cinematics[chapter.IntroCinematic] ~= nil, ("capítulo %s: tiene cabecera (%s)"):format(id, tostring(chapter.IntroCinematic)))
		if id ~= "Adulto_TuVida" then
			check((chapter.OutroCinematic ~= nil and Cinematics[chapter.OutroCinematic] ~= nil) or MONTAGE_END[id], ("capítulo %s: tiene final de episodio"):format(id))
		end
	end
end
for _, old in { "Nino_AInstituto", "Adol_Selectividad" } do
	check(Cinematics[old] == nil, ("%s ya no es un vuelo de cámara viejo"):format(old))
end

---------------------------------------------------------------------
print("6. El final de la vida")
---------------------------------------------------------------------
do
	local def = HappeningIndex.get("Vida_MirarAtras")
	local slots = {}
	for _, photo in def.Photos do
		slots[photo.Slot] = true
	end
	local n = 0
	for _ in slots do
		n += 1
	end
	check(n == 5, "el álbum: una foto por etapa (bebé, niño, adolescente, joven, adulto)")
	local function family(judge)
		local ex = Sequencer.expand(def, Sequencer.resolve(def, judge))
		local who = {}
		for _, a in ex.Tracks.Actors do
			if a.Enter and (a.Enter.Key == "Hija" or a.Enter.Key == "Pareja" or a.Enter.Key == "Familia") then
				table.insert(who, a.Enter.Key)
			end
		end
		return who
	end
	local f1, f2, f3 = family(FULL), family(life({ Flags = { "TienePareja" } })), family(EMPTY)
	check(#f1 == 1 and f1[1] == "Hija", "con la promesa de los hijos: te espera tu hija (y tu nieta)")
	check(#f2 == 1 and f2[1] == "Pareja", "con pareja: te espera tu pareja")
	check(#f3 == 1 and f3[1] == "Familia", "si no: te espera tu familia de siempre")
	local ex = Sequencer.expand(def, Sequencer.resolve(def, FULL))
	local arrivals = {}
	for _, a in ex.Tracks.Actors do
		if a.Enter and a.Enter.Walk == true and a.At > 30 then
			arrivals[a.Enter.Npc] = true
		end
	end
	check(arrivals.Omar and arrivals.Nico and arrivals.Sara and arrivals.Lucia and arrivals.Mateo and arrivals.Hugo and arrivals.Leire and arrivals.Bruno, "la gente que conociste llega andando (y los que se sumaron, también)")
	local exEmpty = Sequencer.expand(def, Sequencer.resolve(def, EMPTY))
	local mateo = false
	for _, a in exEmpty.Tracks.Actors do
		mateo = mateo or (a.Enter ~= nil and a.Enter.Npc == "Mateo")
	end
	check(not mateo, "quien no conociste no viene")
	check(def.FadeOut == true and Sequencer.compile("Vida_MirarAtras", def).Duration >= 45, "un final largo, que funde a negro")
end

L.finish("test-etapas")
