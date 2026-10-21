-- Prueba de la CINEMATECA (modo pruebas: ver todas las escenas una por una) fuera de Roblox, con Lune.
--
-- Uso (desde roblox/):  lune run scripts/test-cinemateca.luau
--
-- Con la historia de verdad (scripts/lib/StoryHarness: LifeStoryService, HappeningService,
-- DialogueService, TesterService reales) comprueba:
--   1. La lista tiene TODAS las escenas del motor (HappeningIndex) y TODAS las conversaciones de las
--      misiones, sin repetidas, por grupos; y el buscador.
--   2. Solo los testers: a un jugador normal el panel no le pone nada.
--   3. Ver / Siguiente / Anterior / Repetir (índices), cada escena acaba y avisa (Ended).
--   4. SANDBOX: ver TODAS las escenas del motor y una muestra de conversaciones no cambia NADA de la
--      partida (perfil entero: historia, marcas, dinero, mochila, memoria del mundo…).
--   5. Te lleva a su sitio y te devuelve donde estabas, también si la cortas a mitad (Stop / otra).
--   6. Revisiones: se apuntan con su contexto y se escriben en el registro («[CINEMATECA] …»).

local H = require("./lib/StoryHarness")
local check = H.check

local Story = H.boot()
local _ = Story
local ROOT = H.ROOT
local Tester = H.loadModule(ROOT .. "/server/Services/TesterService")
local Cine = H.loadModule(ROOT .. "/server/Services/CinematecaService")
local CineList = H.loadModule(ROOT .. "/shared/LifeStory/Cinemateca")
local HappeningIndex = H.loadModule(ROOT .. "/shared/LifeStory/HappeningIndex")
local Legacy = H.loadModule(ROOT .. "/shared/LifeStory/Cinematics")
-- DataStore de mentira (las pruebas nunca escriben uno de verdad)
local storeName = nil
local fakeStore = { data = {}, writes = 0 }
function fakeStore:UpdateAsync(key, fn)
	local new = fn(self.data[key])
	if new ~= nil then
		self.data[key] = new
		self.writes += 1
	end
	return self.data[key]
end
function fakeStore:GetAsync(key)
	return self.data[key]
end
local scheduled = 0
Cine._inject({
	store = function()
		storeName = Cine.STORE
		return fakeStore
	end,
	later = function()
		scheduled += 1 -- (la tanda se escribe a mano: sin esperar 20 s)
	end,
})
Cine.init()

local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local CFrame = roblox.CFrame
local Vector3new = roblox.Vector3.new

---------------------------------------------------------------------
print("1. La lista: todas las escenas y conversaciones")
---------------------------------------------------------------------
local list = CineList.list()
local keys = {}
local dup = 0
for _, e in list do
	if keys[e.Key] then
		dup += 1
	end
	keys[e.Key] = e
end
local missing = {}
for id in HappeningIndex.all() do
	if not keys["E:" .. id] then
		table.insert(missing, id)
	end
end
check(#missing == 0, ("todas las escenas del motor están (%d)%s"):format(#list, if #missing > 0 then ": faltan " .. table.concat(missing, ", ") else ""))
for _, id in Legacy.Ids do
	check(keys["E:" .. id] ~= nil and keys["E:" .. id].Group:find("Capítulos", 1, true) ~= nil, id .. ": de las 21 de capítulo, en su grupo")
end
local dialogues, dmissing = 0, {}
for qid, quest in H.Quests do
	for name in (type(quest) == "table" and quest.Dialogues) or {} do
		dialogues += 1
		if not keys[("D:%s/%s"):format(qid, name)] then
			table.insert(dmissing, qid .. "/" .. tostring(name))
		end
	end
end
check(dialogues > 100 and #dmissing == 0, ("todas las conversaciones de las misiones están (%d)%s"):format(dialogues, if #dmissing > 0 then ": faltan " .. table.concat(dmissing, ", ", 1, math.min(5, #dmissing)) else ""))
check(dup == 0, "ninguna repetida")
local groups = {}
for _, e in list do
	groups[e.Group] = (groups[e.Group] or 0) + 1
	check(e.Index ~= nil and list[e.Index] == e, "cada una sabe su número") -- (se repite: barato)
end
local ngroups = 0
for _ in groups do
	ngroups += 1
end
check(ngroups >= 6 and groups["🪐 Tefra (planeta)"] ~= nil and groups["🌌 Saga de la Grieta"] ~= nil, ("por grupos: saga, capítulos, planeta… (%d grupos)"):format(ngroups))
print(("     %d escenas y conversaciones en %d grupos"):format(#list, ngroups))
local brief = CineList.brief()
check(#CineList.filter(brief, "GRIETA_CAEN") >= 1, "el buscador encuentra por id (sin mayúsculas)")
check(#CineList.filter(brief, "tefra") >= 5 and #CineList.filter(brief, "") == #brief, "y por grupo (Tefra); vacío = todas")

---------------------------------------------------------------------
print("2. Solo testers")
---------------------------------------------------------------------
local tester = H.newPlayer("Revisor", "Adulto", 100)
local normal = H.newPlayer("Normal", "Adulto", 100)
H.Config.Testers = { tester.UserId }
task.wait(0.3)
check(Tester.handle(normal, "Action", "Cinemateca", { Op = "Play", Index = 1 }) == false, "a un jugador normal no le pone ninguna escena")
check(Tester.handle(tester, "Action", "Cinemateca", { Op = "Open" }) == true, "el tester abre la Cinemateca")

---------------------------------------------------------------------
print("3-5. Ver, siguiente, anterior, repetir · sandbox · ir y volver")
---------------------------------------------------------------------
-- Dónde está el tester y adónde le llevan
local home = CFrame.new(10, 3, 20)
local root = { CFrame = home, Position = home.Position }
local moves = {}
local sent = {}
local printed = {}
Cine._inject({
	root = function(_p)
		return root
	end,
	teleport = function(_p, cf)
		root.CFrame, root.Position = cf, cf.Position
		table.insert(moves, cf)
	end,
	locate = function(_p, place)
		return CFrame.new(500, 0, #place * 10) -- (cada sitio, en otro punto)
	end,
	send = function(_p, payload)
		table.insert(sent, payload)
	end,
	print = function(text)
		table.insert(printed, text)
	end,
})
local function lastSent(op)
	for i = #sent, 1, -1 do
		if sent[i].Op == op then
			return sent[i]
		end
	end
	return nil
end
-- Una foto de la partida entera (para ver que no cambia nada)
local function snapshot(value: any, seen: { [any]: boolean }?): string
	local t = type(value)
	if t ~= "table" then
		return if t == "function" then "fn" else tostring(value)
	end
	seen = seen or {}
	if (seen :: any)[value] then
		return "<ciclo>"
	end
	(seen :: any)[value] = true
	local ks = {}
	for k in value do
		table.insert(ks, tostring(k))
	end
	table.sort(ks)
	local parts = {}
	for _, k in ks do
		local v = value[k]
		if v == nil then
			v = value[tonumber(k) or k]
		end
		table.insert(parts, k .. "=" .. snapshot(v, seen))
	end
	return "{" .. table.concat(parts, ",") .. "}"
end
local profile = H.profiles[tester]
-- (lo único que cambia solo con el tiempo de juego: relojes de la partida; no es de las escenas)
local CLOCKS = { { "Life", "StageSeconds" }, { "Story", "Clock" }, { "Stats", "PlaySeconds" } }
local function photo(): string
	local saved = {}
	for i, path in CLOCKS do
		local t = profile[path[1]]
		if type(t) == "table" then
			saved[i] = t[path[2]]
			t[path[2]] = nil
		end
	end
	local text = snapshot(profile)
	for i, path in CLOCKS do
		local t = profile[path[1]]
		if type(t) == "table" then
			t[path[2]] = saved[i]
		end
	end
	return text
end
local before = photo()
local beforeParts = {}
for k, v in profile do
	beforeParts[k] = snapshot(v)
end
local function changedParts(): { string }
	local out = {}
	for k, v in profile do
		if beforeParts[k] ~= snapshot(v) then
			table.insert(out, tostring(k))
		end
	end
	return out
end

-- Ver la primera, siguiente, anterior, repetir
check(Tester.handle(tester, "Action", "Cinemateca", { Op = "Play", Index = 1 }) == true, "▶ Ver la 1")
task.wait(0.05)
check(Cine.current(tester).Index == 1 and lastSent("Ended") ~= nil, "la 1 se ve y acaba (Ended)")
Tester.handle(tester, "Action", "Cinemateca", { Op = "Next" })
task.wait(0.3)
check(Cine.current(tester).Index == 2, "⏭ Siguiente: la 2")
Tester.handle(tester, "Action", "Cinemateca", { Op = "Prev" })
task.wait(0.3)
check(Cine.current(tester).Index == 1, "⏮ Anterior: otra vez la 1")
Tester.handle(tester, "Action", "Cinemateca", { Op = "Replay" })
task.wait(0.3)
check(Cine.current(tester).Index == 1 and lastSent("Started").Index == 1, "↺ Repetir: la 1")
Tester.handle(tester, "Action", "Cinemateca", { Op = "Prev" })
task.wait(0.3)
check(Cine.current(tester).Index == #list, "⏮ desde la primera: la última")

-- TODAS las escenas del motor (en el doble no hay pantalla: cada una acaba en el acto) y 40 conversaciones
local bad, played = {}, 0
local convs = 0
for _, e in list do
	if e.Kind ~= "Conversación" or convs < 40 then
		if e.Kind == "Conversación" then
			convs += 1
		end
		local ok = Cine.play(tester, e.Index)
		if not ok then
			table.insert(bad, e.Key)
		end
		played += 1
		if e.Kind == "Conversación" then
			Cine.stop(tester) -- (la conversación se corta: así no hay que leerla entera)
		end
		task.wait()
	end
end
task.wait(0.5)
Cine.close(tester)
check(#bad == 0, ("se pueden poner todas (%d puestas)%s"):format(played, if #bad > 0 then ": " .. table.concat(bad, ", ", 1, math.min(8, #bad)) else ""))
local after = photo()
local changed = changedParts()
check(after == before, "SANDBOX: después de verlas todas, la partida es EXACTAMENTE la misma (historia, marcas, dinero, mochila, memoria del mundo)" .. (if after ~= before then ": cambia " .. table.concat(changed, ", ") else ""))
-- (control: la misma escena SIN sandbox sí deja cráteres; así se sabe que la prueba mira de verdad)
local Happening = H.loadModule(ROOT .. "/server/Services/HappeningService")
Happening.play(normal, "Grieta_Caen")
task.wait(0.1)
local normalWorld = H.profiles[normal].Story and H.profiles[normal].Story.World
check(normalWorld ~= nil and normalWorld["Cielo.Crater.Parque"] ~= nil, "(control: sin sandbox, Grieta_Caen sí deja su cráter en la partida)")
local world = profile.Story and profile.Story.World
check(world == nil or world["Cielo.Crater.Parque"] == nil, "(memoria del mundo intacta: Grieta_Caen no ha dejado cráteres)")
check(root.CFrame == home, "y estás donde empezaste")
local wentAway = false
for _, cf in moves do
	wentAway = wentAway or (cf.Position - home.Position).Magnitude > 50
end
check(wentAway, "cada escena te lleva a su sitio")

-- Cortarla a mitad: con una pantalla que no acaba sola (doble de HappeningService)
local running = {}
local finishedFn = nil
Cine._inject({
	happening = function()
		return {
			play = function(_p, id, opts)
				running[id] = opts
				return 30
			end,
			skip = function(_p, id)
				running[id] = nil
				if finishedFn then
					task.spawn(finishedFn, tester, id, true)
				end
				return true
			end,
			checker = function()
				return function()
					return true
				end
			end,
			onFinished = function(fn)
				finishedFn = fn
			end,
		}
	end,
})
Cine.init() -- (se apunta al final de las escenas del doble)
local caen = keys["E:Grieta_Caen"]
sent = {}
check(Cine.play(tester, caen.Index) == true and running.Grieta_Caen and running.Grieta_Caen.Sandbox == true, "las escenas del motor se ponen en SANDBOX")
check(root.CFrame ~= home, "te lleva a su sitio")
Cine.stop(tester)
task.wait(0.05)
local ended = lastSent("Ended")
check(ended and ended.Skipped == true and ended.Key == "E:Grieta_Caen", "cortarla a mitad: la pantalla sabe que acabó (saltada)")
check(root.CFrame == home, "…y vuelves donde estabas")
-- Pasar a otra a mitad: corta la de antes, te lleva a la nueva y al acabar vuelves igual
Cine.play(tester, caen.Index)
Cine.next(tester)
task.wait(0.05)
check(running.Grieta_Caen == nil, "⏭ a mitad corta la de antes")
Cine.close(tester)
check(root.CFrame == home, "y al cerrar vuelves a tu sitio")

---------------------------------------------------------------------
print("6. Revisiones")
---------------------------------------------------------------------
sent, printed = {}, {}
check(Tester.handle(tester, "Action", "Cinemateca", { Op = "Review", Key = "E:Grieta_Caen", Ok = false, Note = "el tercer impacto\nse ve corto", Shot = 6, Shots = 13, T = 8.2, Device = "Móvil 844x390", Skipped = true }) == true, "❌ Mal con nota y contexto")
local r = Cine.reviews()[#Cine.reviews()]
check(r and r.Key == "E:Grieta_Caen" and r.Ok == false and r.Shot == 6 and r.Shots == 13 and r.Device == "Móvil 844x390" and r.Skipped == true and type(r.Time) == "number", "se apunta con la escena, el plano, el dispositivo y la hora")
check(r and r.Note and not r.Note:find("\n", 1, true), "la nota, en una línea (limpia)")
check(#printed == 1 and printed[1]:find("[CINEMATECA]", 1, true) ~= nil and printed[1]:find("Grieta_Caen", 1, true) ~= nil, "y se escribe en el registro del servidor («[CINEMATECA] …»)")
check(Cine.verdicts()["E:Grieta_Caen"] == "Mal" and lastSent("Reviewed") ~= nil, "la escena queda marcada como revisada (Mal)")
check(Tester.handle(tester, "Action", "Cinemateca", { Op = "Review", Key = "E:NoExiste", Ok = true }) == false, "una escena que no existe no se apunta")
check(Tester.handle(normal, "Action", "Cinemateca", { Op = "Review", Key = "E:Grieta_Caen", Ok = true }) == false, "un jugador normal no puede apuntar nada")
Tester.handle(tester, "Action", "Cinemateca", { Op = "Export" })
check(Cine.export():find("Grieta_Caen", 1, true) ~= nil, "«Ver revisiones» las lista")

---------------------------------------------------------------------
print("7. Comentarios: etiquetas, pausa y GUARDADAS en su propio DataStore (de mentira)")
---------------------------------------------------------------------
local frozen = {}
Cine._inject({
	happening = function()
		return {
			freeze = function(_p, on)
				table.insert(frozen, on)
				return true
			end,
			onFinished = function() end,
		}
	end,
})
check(Tester.handle(tester, "Action", "Cinemateca", { Op = "Pause" }) == true and frozen[#frozen] == true, "💬 Comentar para la escena (freeze)")
check(Tester.handle(tester, "Action", "Cinemateca", { Op = "Resume" }) == true and frozen[#frozen] == false, "…y al acabar de comentar sigue")
local writesBefore = fakeStore.writes
check(Tester.handle(tester, "Action", "Cinemateca", { Op = "Review", Key = "E:Adu02_Atardecer", Ok = false, Tags = { "Cámara mal", "Texto tapa", "inventada" }, Note = "mira desde arriba a la cabeza de Abu" }) == true, "❌ con etiquetas")
local last = Cine.reviews()[#Cine.reviews()]
check(last.Tags and #last.Tags == 2 and last.Tags[1] == "Cámara mal" and last.Tags[2] == "Texto tapa", "solo se guardan las etiquetas que existen")
check(scheduled >= 1 and fakeStore.writes == writesBefore, "se guardan por tandas (no una escritura por revisión)")
local saved = Cine.flush()
check(saved >= 1 and storeName == "CinematecaRevisiones_v1", ("la tanda se guarda en su DataStore aparte, «CinematecaRevisiones_v1» (%d revisiones)"):format(saved))
local Config = H.Config
check(Config.DataStoreName ~= "CinematecaRevisiones_v1", "(nunca el de las partidas)")
local index = fakeStore.data.indice
check(type(index) == "table" and #index == 1 and index[1]:match("^dia_%d%d%d%d%d%d%d%d$") ~= nil, "con un índice de días")
local day = fakeStore.data[index[1]]
check(type(day) == "table" and day[#day].k == "E:Adu02_Atardecer" and day[#day].ok == 0 and day[#day].g[1] == "Cámara mal", "cada revisión, corta (escena, ✅/❌, etiquetas, nota…)")
check(Cine.flush() == 0, "lo ya guardado no se vuelve a escribir")
-- Una página llena pasa a la siguiente
local savedPage = Cine.PAGE
Cine.PAGE = #day
check(Tester.handle(tester, "Action", "Cinemateca", { Op = "Review", Key = "E:Grieta_Caen", Ok = true }) == true and Cine.flush() == 1, "con la página llena…")
check(fakeStore.data[index[1] .. "_2"] ~= nil and #fakeStore.data.indice == 2, "…sigue en «_2» (y el índice la apunta)")
Cine.PAGE = savedPage
printed = {}
sent = {}
Cine._inject({ send = function(_p, payload) table.insert(sent, payload) end })
local text = Cine.exportAll(tester)
local fromStore = 0
for _, l in printed do
	if l:find("[CINEMATECA]", 1, true) then
		fromStore += 1
	end
end
check(fromStore >= 3 and text:find("Adu02_Atardecer", 1, true) ~= nil and text:find("Cámara mal", 1, true) ~= nil, "«/cinemateca exportar»: lee las guardadas, al registro y al panel")
check(lastSent("Export") ~= nil, "…y el panel las enseña")
-- Un DataStore que falla: no se pierde nada (vuelven a la cola)
Cine._inject({ store = function() error("DataStore caído") end })
Tester.handle(tester, "Action", "Cinemateca", { Op = "Review", Key = "E:Grieta_Caen", Ok = false })
check(Cine.flush() == 0, "si el DataStore falla, no se guarda…")
Cine._inject({ store = function() return fakeStore end })
check(Cine.flush() == 1, "…y se guarda en la tanda siguiente")
-- /cinemateca exportar por el chat
check(Tester.chat(tester, "/cinemateca exportar") == true and Tester.chat(normal, "/cinemateca exportar") == false, "«/cinemateca exportar» en el chat (solo testers)")

---------------------------------------------------------------------
print("8. Cada escena en SU sitio, con su gente en sus marcas (v125.5: se ponían donde estabas)")
---------------------------------------------------------------------
local withPlace, here = 0, {}
for _, e in list do
	local has = e.Place or e.Before or (e.Actors and e.Actors[1])
	if not has and e.Id then
		local def = HappeningIndex.get(e.Id)
		for _, spec in (def and def.Anchors) or {} do
			if type(spec) == "table" or (type(spec) == "string" and (spec:find("^Place:") or spec:find("^Zone:"))) then
				has = true
			end
		end
	end
	if has then
		withPlace += 1
	else
		table.insert(here, e.Key)
	end
end
print(("     con sitio: %d de %d; sin sitio fijo (pasan donde estés): %d"):format(withPlace, #list, #here))
-- (las que no tienen sitio fijo son las que en el juego pasan donde estés: llamadas, montajes, sueños…)
check(withPlace >= 900 and withPlace / #list > 0.65, ("la gran mayoría saben dónde pasan (%d de %d)"):format(withPlace, #list))
local adu = keys["E:Adu02_Atardecer"]
check(adu.Place == "Playa" and adu.Actors and adu.Actors[1].Npc == "Abu", "El atardecer con Abu: en la playa, con Abu en su marca (del paso de la misión)")
local played = {}
local located = {}
Cine._inject({
	locate = function(_p, place, options)
		table.insert(located, place)
		if place:sub(1, 6) == "Tefra_" then
			return nil -- (Tefra sin construir)
		end
		return CFrame.new(1000 + #place, 0, 2000 + ((options and options.Offset and options.Offset.Z) or 0))
	end,
	happening = function()
		return {
			play = function(_p, id, opts)
				played[id] = opts
				return 5
			end,
			skip = function() return true end,
			checker = function() return function() return true end end,
			onFinished = function() end,
			freeze = function() return true end,
		}
	end,
})
root.CFrame, root.Position = home, home.Position
moves = {}
sent = {}
check(Cine.play(tester, adu.Index) == true, "▶ El atardecer con Abu")
local stageMove = moves[1]
check(stageMove ~= nil and (stageMove.Position - Vector3new(1005, 3, 2000)).Magnitude < 0.01, "te lleva a la playa (no se queda donde estabas)")
check(played.Adu02_Atardecer and played.Adu02_Atardecer.StandIns and played.Adu02_Atardecer.StandIns.Abu ~= nil, "y Abu tiene su marca para aparecer (StandIns), aunque la misión no esté activa")
Cine.stop(tester)
local tefra = nil
for _, e in list do
	if e.Kind ~= "Conversación" and e.Place and e.Place:sub(1, 6) == "Tefra_" then
		tefra = e
		break
	end
end
moves = {}
sent = {}
check(tefra ~= nil and Cine.play(tester, tefra.Index) == false, "una de Tefra sin la ciudad construida NO se pone…")
local why = lastSent("Started")
check(why and why.Ok == false and why.Why == "Lugar no disponible" and #moves == 0, "…dice «Lugar no disponible» y no te mueve")
Cine.close(tester)

print(if H.failures == 0 then "\n✅ test-cinemateca: todo correcto" else ("\n❌ test-cinemateca: %d fallos"):format(H.failures))
process.exit(if H.failures == 0 then 0 else 1)
