-- test-deriva: el primer pecio de la Deriva (la Misericordia) y su misión «La nave hospital»
-- (docs/espacio-aaa/expansion-15h.md). lune run scripts/test-deriva.luau

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local Vector3 = roblox.Vector3
local check = L.check

local Derelicts = L.load("src/shared/Cosmos/Derelicts")
local Stations = L.load("src/shared/Cosmos/Stations")
local Layers = L.load("src/shared/Cosmos/Layers")
local d = Derelicts.Misericordia

print("🛰 El pecio en el espacio")
local o = d.Origin
check(Layers.inColumn(o) and o.Y > Layers.SpaceY + 300, "la Misericordia está en la columna del espacio, por encima de donde empieza")
local farFromStations = true
for _, s in Stations.List do
	if (s.Center - o).Magnitude < 1500 then
		farFromStations = false
	end
end
check(farFromStations, "lejos de las estaciones")
check(Derelicts.hullHit(o + Vector3.new(0, 8, 0), 6) ~= nil and Derelicts.hullHit(o + Vector3.new(0, 300, 0), 6) == nil, "la nave choca con el casco y no con el vacío de encima")
local dock = Derelicts.world(d, d.Dock)
check(Derelicts.dockAt(dock) == d and Derelicts.hullHit(dock, 6) == nil, "el aro de la esclusa está fuera del casco y se puede atracar")
check(Derelicts.hullHit(Derelicts.world(d, d.Launch), 8) == nil, "al volver, la nave sale fuera del casco")
check(Derelicts.inside(d, Derelicts.world(d, d.Entry)) and Derelicts.roomAt(d, Derelicts.world(d, d.Entry)) == "Esclusa", "apareces dentro, en la esclusa")

print("🔦 Dentro")
for _, f in d.Fuses do
	check(Derelicts.roomAt(d, Derelicts.world(d, f.P)) == f.Room, ("el fusible %d está en %s"):format(f.N, f.Room))
end
for _, lg in d.Logs do
	check(Derelicts.roomAt(d, Derelicts.world(d, lg.P)) == lg.Room, ("el registro de %s está en su sala"):format(lg.Room))
end
check(Derelicts.roomAt(d, Derelicts.world(d, d.Core)) == "Puente", "el núcleo está en el puente")
local ons, offs = 0, 0
for i = 0, 99 do
	if Derelicts.laserOn(d, 1, i * 0.1) then
		ons += 1
	else
		offs += 1
	end
end
check(ons > 0 and offs > 15, "las barreras láser se apagan lo bastante para cruzar")
check(Derelicts.inLaser(d, 1, Derelicts.world(d, Vector3.new(d.Lasers[1].X, 3, 0))) and not Derelicts.inLaser(d, 1, Derelicts.world(d, Vector3.new(d.Lasers[1].X + 10, 3, 0))), "la barrera solo daña a quien la cruza")
check(Derelicts.damageFor(d, 100, 20) == 20 and Derelicts.damageFor(d, 20, 20) == 5 and Derelicts.damageFor(d, 15, 20) == 0, "nada de dentro te deja por debajo de 15 de vida")
local warned, burst = false, false
for i = 0, 99 do
	local s = Derelicts.sparkState(d, i * 0.1)
	warned = warned or s == "Warn"
	burst = burst or s == "Burst"
end
check(warned and burst, "las chispas avisan antes de la descarga")

print("📜 La misión")
local story = { Active = { [Derelicts.MissionId] = { Step = 4, Sub = { ["1"] = true, ["3"] = true } } }, Completed = {} }
local ph = Derelicts.phaseOf(story)
check(ph and ph.Step == "Fuses" and Derelicts.power(ph) == 2, "con dos fusibles: corriente 2 de 3")
story.Active[Derelicts.MissionId] = { Step = 5 }
check(Derelicts.power(Derelicts.phaseOf(story)) == 3, "después de los fusibles: corriente entera (puerta del puente abierta)")
story.Active[Derelicts.MissionId] = { Step = 2 }
check(Derelicts.power(Derelicts.phaseOf(story)) == 0, "antes: sin corriente")
check(not Derelicts.offer({ Completed = {} }) and Derelicts.offer({ Completed = { Varkun_02_Escarcha = 1 }, Active = {} }), "se ofrece después del prólogo de Varkun")
check(not Derelicts.offer({ Completed = { Varkun_02_Escarcha = 1, [Derelicts.MissionId] = 1 } }), "y una sola vez")
for _, s in Derelicts.Steps do
	local row = Derelicts.row({ Step = s, Index = 1, Fuses = {} }, Vector3.new(0, 0, 0))
	if not row or type(row.Title) ~= "string" then
		check(false, "fila del HUD para " .. s)
	end
end
check(true, "cada paso tiene su fila en el HUD de la nave")

local missions = L.load("src/shared/LifeStory/Misiones/Deriva_ActoI")
local m = missions[1]
check(m.Id == Derelicts.MissionId and #m.Steps == #Derelicts.Steps, "la misión tiene los pasos que cuenta el servicio")
check(m.Steps[3].Type == "Cinematic" and m.Steps[3].Id == "Deriva_Misericordia_Entrada" and m.Steps[6].Id == "Deriva_Misericordia_Registro", "con sus dos cinemáticas en su sitio")
check(m.Steps[4].Type == "Group" and m.Steps[4].Need == 3, "los tres fusibles son un grupo de 3")

print("🎬 Escenas, guion y sitios")
local scenes = L.load("src/shared/LifeStory/Happenings/Deriva")
for _, id in { "Deriva_Misericordia_Entrada", "Deriva_Misericordia_Registro", "Deriva_Registro_Triaje", "Deriva_Registro_Cuarentena", "Deriva_Registro_Comunicaciones", "Deriva_Alba_Fin" } do
	check(scenes[id] ~= nil, "escena " .. id)
end
for _, lg in d.Logs do
	check(scenes[lg.Scene] ~= nil and scenes[lg.Scene].Light == true, "el registro " .. lg.Id .. " es una escena ligera (sigues andando)")
end
local texts = {}
for _, sc in scenes do
	for _, line in (sc.Tracks.Dialogue or {}) do
		table.insert(texts, line.T)
	end
end
local all = table.concat(texts, " ")
check(string.find(all, "V, I, G", 1, true) ~= nil, "la pista de la Vigilancia (VIG) está en el último registro")
local modern = { "🪡", "🪙", "🫧", "🪟", "🪪", "🥸", "🪃", "🪨", "🪸", "🪜", "🪞", "🪶", "🪵", "🪼", "🫙", "🥷", "🩷", "🪖", "🪴", "🪲", "🫘", "🪣" }
local bad = false
for _, e in modern do
	if string.find(all, e, 1, true) then
		bad = true
	end
end
check(not bad, "sin emoji modernos (en Roblox salen como ▯)")
check(fs.isFile("src/shared/LifeStory/Guiones/Deriva_01_Misericordia.luau"), "guion de radio generado desde docs/historia/reescritura")
local loc = fs.readFile("src/shared/LifeStory/Locations.luau")
check(string.find(loc, "\"Deriva_\" .. s.Id", 1, true) ~= nil, "los sitios del pecio están en Locations (Deriva_<Id>)")
local builder = fs.readFile("src/server/World/DerelictBuilder.luau")
check(string.find(builder, "\"StorySpot\"", 1, true) ~= nil and string.find(builder, "PecioLaser", 1, true) ~= nil and string.find(builder, "PecioLuz", 1, true) ~= nil, "el constructor pone sitios, láseres y luces")
local space = fs.readFile("src/server/Services/SpaceService.luau")
check(string.find(space, "function SpaceService.dockDerelict", 1, true) ~= nil and string.find(space, "Derelicts.dockAt(st.Pos)", 1, true) ~= nil and string.find(space, "function SpaceService.boardAt", 1, true) ~= nil, "se atraca en la esclusa con Salir y se vuelve a la nave desde dentro")
local zone = fs.readFile("src/shared/Cosmos/Zone.luau")
check(string.find(zone, "Derelicts.hullHit(pos, radius)", 1, true) ~= nil, "la nave no atraviesa el pecio")

L.finish("test-deriva")
