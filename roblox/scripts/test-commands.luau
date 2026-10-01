-- Prueba del menú de comandos y de los carteles de "pulsa E" FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-commands.luau
--
-- Comprueba las reglas que no dibujan nada:
--   * Commands/MenuLogic: la lista de cosas que tienes delante no baila al andar (ni cuando los
--     compañeros se mueven), lo elegido no salta cada vez que se refresca (cada 0,4 s), y no se usan
--     carteles lejanos, ocultos o en plena conversación.
--   * Controllers/PromptGuard: los carteles siguen apagados un momento después de una conversación, y
--     el de hablar con alguien no vuelve mientras está su globo (en el móvil, un toque de más ya no
--     repite la conversación).
--   * Commands/PhoneApps: sin el menú COMANDOS, TODO lo que había en él se sigue alcanzando: las
--     acciones de ahora (hablar, entrar, comprar billete, saludar, bajarse, atacar, disparar, apuntar,
--     recargar, robar, detener…) en la tira de acciones y lo demás (mapa, mochila, las apps, el pase,
--     modo pruebas y todo «Más») como apps del ValPhone; con calma y en plena pelea. También que cada
--     comando de DefaultCommands y cada Hud.addButton del juego está en la lista (si se añade uno
--     nuevo, esta prueba lo pide) y tiene su icono y color de app.
--   * UI/PhoneInbox: los mensajes del teléfono (sin leer, leídos, quién los enseña).

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function load(path: string, env: { [string]: any }?): any
	local environment = setmetatable(env or {}, { __index = _G })
	return luau.load(fs.readFile(path), { debugName = path, environment = environment })()
end

local MenuLogic = load("src/client/Commands/MenuLogic.luau")
local fakeGame = {
	GetService = function(_, name)
		return { Name = name }
	end,
}
local PromptGuard = load("src/client/Controllers/PromptGuard.luau", { game = fakeGame })
local PhoneApps = load("src/client/Commands/PhoneApps.luau")
local PhoneInbox = load("src/client/UI/PhoneInbox.luau")

local function ids(list): string
	local out = {}
	for _, item in list do
		table.insert(out, item.Key)
	end
	return table.concat(out, ",")
end
local function key(item)
	return item.Key
end

---------------------------------------------------------------------
print("\n▶ Lo que tienes delante, sin bailar")
local order = {}
local list = { { Key = "Nico", Distance = 6 }, { Key = "Puerta", Distance = 3 }, { Key = "Sara", Distance = 8 } }
local sorted
sorted, order = MenuLogic.orderTargets(order, list, key)
check(ids(sorted) == "Puerta,Nico,Sara", "La primera vez, del más cercano al más lejano")
-- Nico y Sara andan: Sara queda un poco más cerca que Nico, pero no mucho
list = { { Key = "Nico", Distance = 6.5 }, { Key = "Puerta", Distance = 3.2 }, { Key = "Sara", Distance = 5.8 } }
sorted, order = MenuLogic.orderTargets(order, list, key)
check(ids(sorted) == "Puerta,Nico,Sara", "Si otro se acerca solo un poco, nadie cambia de sitio (antes saltaba cada 0,4 s)")
list = { { Key = "Nico", Distance = 9 }, { Key = "Puerta", Distance = 7 }, { Key = "Sara", Distance = 2 } }
sorted, order = MenuLogic.orderTargets(order, list, key)
check(ids(sorted) == "Sara,Puerta,Nico", "Si alguien está CLARAMENTE más cerca, pasa delante")
list = { { Key = "Sara", Distance = 2 }, { Key = "Puerta", Distance = 3.2 }, { Key = "Nico", Distance = 9 }, { Key = "Banco", Distance = 2.5 } }
sorted, order = MenuLogic.orderTargets(order, list, key)
check(#sorted == 4 and sorted[1].Key == "Sara" and sorted[2].Key == "Banco", "Lo nuevo entra en su hueco por distancia")
list = { { Key = "Sara", Distance = 2 }, { Key = "Nico", Distance = 9 } }
sorted, order = MenuLogic.orderTargets(order, list, key)
check(ids(sorted) == "Sara,Nico" and #order == 2, "Lo que se va desaparece de la lista (sin huecos ni repetidos)")
local same = true
local stable = { { Key = "A", Distance = 4 }, { Key = "B", Distance = 4.5 }, { Key = "C", Distance = 5 } }
local o = {}
local first
first, o = MenuLogic.orderTargets(o, stable, key)
for step = 1, 50 do
	-- Distancias que tiemblan un poco (andar, compañeros que se mueven)
	local jitter = {
		{ Key = "A", Distance = 4 + math.sin(step) * 1.2 },
		{ Key = "B", Distance = 4.5 + math.cos(step * 1.3) * 1.2 },
		{ Key = "C", Distance = 5 + math.sin(step * 0.7) * 1.2 },
	}
	local now
	now, o = MenuLogic.orderTargets(o, jitter, key)
	if ids(now) ~= ids(first) then
		same = false
	end
end
check(same, "50 refrescos con distancias que tiemblan: la lista no se mueve ni una vez")

---------------------------------------------------------------------
print("\n▶ Lo elegido no salta")
local old = { { Id = "Aqui1", Prompt = true }, { Id = "Aqui2", Prompt = true }, { Id = "Mapa" }, { Id = "Mas" } }
local new = { { Id = "Aqui2", Prompt = true }, { Id = "Aqui1", Prompt = true }, { Id = "Mapa" }, { Id = "Mas" } }
check(MenuLogic.pickIndex(old, 3, new, 10) == 3, "Tenías «Mapa» elegido: sigue elegido aunque cambie la lista (aunque lleves rato sin tocar)")
check(MenuLogic.pickIndex(old, 2, new, 1) == 1, "Tenías el 2.º cartel: si sube al 1.º, sigue siendo el tuyo")
local withNew = { { Id = "Aqui7", Prompt = true }, { Id = "Aqui1", Prompt = true }, { Id = "Mapa" }, { Id = "Mas" } }
check(MenuLogic.pickIndex(old, 3, withNew, 1) == 3, "Aparece algo nuevo delante mientras usas el menú: no te cambia la selección")
check(MenuLogic.pickIndex(old, 3, withNew, 6) == 1, "…si llevas un rato sin tocarlo, lo nuevo de delante pasa a elegido")
local gone = { { Id = "Aqui2", Prompt = true }, { Id = "Mapa" }, { Id = "Mas" } }
check(MenuLogic.pickIndex(old, 4, gone, 1) == 3, "Lo elegido ya no está: se queda en la misma fila (sin salirse)")
check(MenuLogic.pickIndex(old, 1, {}, 1) == 1, "Lista vacía: no se rompe")
local current = 2
local items = old
for step = 1, 30 do
	-- Refresco cada 0,4 s con la misma lista (en otro orden a veces): la selección no se mueve
	local now = if step % 2 == 0 then new else old
	current = MenuLogic.pickIndex(items, current, now, step * 0.4)
	items = now
end
check(items[current].Id == "Aqui2", "30 refrescos seguidos: sigue elegido lo mismo")

---------------------------------------------------------------------
print("\n▶ Carteles que se pueden usar")
check(MenuLogic.usable({ Exists = true, Enabled = true, ServiceEnabled = true, Distance = 6, Max = 9 }), "Uno cerca y encendido, sí")
check(not MenuLogic.usable({ Exists = true, Enabled = true, ServiceEnabled = true, Distance = 30, Max = 9 }), "Uno lejos (se quedó «a la vista» sin aviso), no: ya no sale «Hablar» con alguien lejano")
check(not MenuLogic.usable({ Exists = true, Enabled = false, ServiceEnabled = true, Distance = 3, Max = 9 }), "Uno apagado (personaje oculto por tu escena), no")
check(not MenuLogic.usable({ Exists = true, Enabled = true, ServiceEnabled = false, Distance = 3, Max = 9 }), "Con los carteles apagados (conversación), no")
check(not MenuLogic.usable({ Exists = true, Enabled = true, ServiceEnabled = true, Busy = true, Distance = 3, Max = 9 }), "Hablando con alguien, el botón Interactuar no hace nada")
check(not MenuLogic.usable({ Exists = false, Enabled = true, Distance = 3, Max = 9 }), "Uno que ya no existe, no")

---------------------------------------------------------------------
print("\n▶ PromptGuard: una conversación no se repite sola")
check(PromptGuard.locked(true, 0, 5), "En plena conversación, carteles apagados")
check(PromptGuard.locked(false, 10, 10.5), "Medio segundo después de cerrarla, siguen apagados (el toque que la cierra no abre otra)")
check(not PromptGuard.locked(false, 10, 11.2), "Pasado el momento, vuelven")
check(PromptGuard.isTalk("Hablar", false) and PromptGuard.isTalk("Examinar", true) and not PromptGuard.isTalk("Coger comida", false), "Se reconoce un cartel de hablar (dice «Hablar» o cuelga de un personaje)")
check(not PromptGuard.release(13, 12, false), "El cartel de hablar sigue apagado su rato")
check(not PromptGuard.release(13, 14, true), "…y mientras está el globo de lo que te dice")
check(PromptGuard.release(13, 14, false), "…y vuelve cuando el globo se ha ido")

---------------------------------------------------------------------
print("\n▶ Sin COMANDOS: todo se alcanza (tira de acciones o ValPhone)")
-- Lo que había en COMANDOS (Commands/DefaultCommands, Hud.addButton de cada sistema y el pase) con
-- sus prioridades de verdad. «Más» era un grupo: en el teléfono cada hijo es una app.
local MORE_CHILDREN = { "Misiones", "Historia", "Personaje", "Viviendas", "Carrera", "Controles", "Menu" }
local function group(id: string, priority: number, children: { string }, flatten: boolean?)
	return {
		Id = id,
		Label = id,
		Icon = "mas",
		Priority = priority,
		Flatten = flatten,
		Open = function()
			local out = {}
			for i, child in children do
				table.insert(out, { Id = child, Label = child, Icon = "mas", Priority = i })
			end
			return out
		end,
	}
end
local function cmd(id: string, priority: number, extra: { [string]: any }?)
	local out = { Id = id, Label = id, Icon = "mas", Priority = priority }
	for k, v in extra or {} do
		out[k] = v
	end
	return out
end
local APPS = { "AppIr a casa", "AppRuta a casa", "AppTienda", "AppVehículos", "AppGestos", "AppMetro", "AppMercadillo", "AppGuía de pesca" }
local function sorted(list)
	table.sort(list, function(a, b)
		return a.Priority < b.Priority
	end)
	return list
end
local function calmList()
	local list = {
		cmd("Aqui1", 1, { Prompt = true, Accent = true }), cmd("Aqui2", 2, { Prompt = true }), cmd("Aqui3", 3, { Prompt = true }),
		group("AquiMas", 4, { "Aqui4", "Aqui5" }),
		cmd("Registrar", 4.3), cmd("Liberar", 4.4), cmd("Detener", 4.5), cmd("Inspeccionar", 4.6),
		cmd("Saludar", 5), cmd("Bajarse", 6), cmd("Atacar", 7), cmd("Robar", 8),
		cmd("Objetos", 50), cmd("Mensajes", 50.2, { Screen = "Mensajes" }), cmd("Mapa", 51),
		group("GestosPase", 53.75, { "GestoPase_S1" }),
		cmd("PaseTemporada", 55.5, { Badge = true }), cmd("Cartera", 56.5), cmd("Ayuda", 58.5), cmd("ModoPruebas", 59),
		group("Mas", 60, MORE_CHILDREN, true),
	}
	for i, id in APPS do
		table.insert(list, cmd(id, 51.5 + i * 0.5))
	end
	return sorted(list)
end
local function fightList()
	return sorted({
		cmd("Disparar", 0.1, { Stay = true }), cmd("Apuntar", 0.12), cmd("Recargar", 0.14), cmd("Habilidades", 0.15),
		cmd("Objetos", 0.18), cmd("Defender", 0.2), cmd("Huir", 0.3), cmd("GuardarArma", 0.35),
		cmd("Mapa", 51), group("Mas", 60, MORE_CHILDREN, true),
	})
end
local function opener(command)
	return command.Open(nil)
end
local calmContext, calmApps = PhoneApps.split(calmList(), opener)
local fightContext, fightApps = PhoneApps.split(fightList(), opener)
local function ids(list)
	local out = {}
	for _, command in list do
		table.insert(out, command.Id)
	end
	return out
end
local function has(list, id: string): boolean
	return table.find(ids(list), id) ~= nil
end
local FORMER = {
	"Aqui1", "Aqui2", "Aqui3", "AquiMas", "Saludar", "GestosPase", "Bajarse", "Disparar", "Apuntar", "Recargar",
	"GuardarArma", "Atacar", "Habilidades", "Defender", "Huir", "Liberar", "Registrar", "Inspeccionar", "Detener",
	"Robar", "Objetos", "Mapa", "ModoPruebas", "PaseTemporada",
}
for _, id in APPS do
	table.insert(FORMER, id)
end
for _, id in MORE_CHILDREN do
	table.insert(FORMER, id)
end
local allContext, allApps = table.clone(calmContext), table.clone(calmApps)
for _, c in fightContext do
	table.insert(allContext, c)
end
for _, a in fightApps do
	table.insert(allApps, a)
end
local missing = PhoneApps.unreachable(FORMER, allContext, allApps)
check(#missing == 0, ("Los %d comandos que había en COMANDOS se alcanzan todos (tira o teléfono)"):format(#FORMER) .. (if #missing > 0 then ": faltan " .. table.concat(missing, ", ") else ""))
local contextIds = { "Aqui1", "Aqui2", "Aqui3", "AquiMas", "Saludar", "Bajarse", "Atacar", "Robar", "Detener", "Liberar", "Registrar", "Inspeccionar" }
local wrong = {}
for _, id in contextIds do
	if not has(calmContext, id) or has(calmApps, id) then
		table.insert(wrong, id)
	end
end
for _, id in { "Disparar", "Apuntar", "Recargar", "GuardarArma", "Habilidades", "Defender", "Huir" } do
	if not has(fightContext, id) or has(fightApps, id) then
		table.insert(wrong, id)
	end
end
check(#wrong == 0, "Lo de ahora (hablar, entrar, comprar billete, saludar, bajarse, atacar, disparar, apuntar, recargar, robar, detener…) va en la tira, nunca dentro del teléfono" .. (if #wrong > 0 then ": " .. table.concat(wrong, ", ") else ""))
local appWrong = {}
for _, id in { "Objetos", "Mapa", "Mensajes", "Cartera", "Ayuda", "ModoPruebas", "PaseTemporada", "GestosPase", "Misiones", "Historia", "Personaje", "Viviendas", "Carrera", "Controles", "Menu", table.unpack(APPS) } do
	if not has(calmApps, id) or has(calmContext, id) then
		table.insert(appWrong, id)
	end
end
check(#appWrong == 0, "Lo de siempre (Mapa, Mochila, Ir a casa, Tienda, Vehículos, Gestos, Metro, Mercadillo, Pesca, Pase, Modo pruebas, Misiones, Mi historia, Ajustes…) son apps del ValPhone" .. (if #appWrong > 0 then ": " .. table.concat(appWrong, ", ") else ""))
check(not has(calmApps, "Mas") and has(calmApps, "Misiones") and has(calmApps, "Menu"), "«Más» ya no es un submenú: cada hijo es su propia app")
check(has(calmApps, "Objetos") and has(fightContext, "Objetos") and not has(fightApps, "Objetos"), "Objetos es la app Mochila, pero en plena pelea sube a la tira (como antes subía arriba del todo)")
check(PhoneApps.meta(calmApps[1]).Name ~= nil and PhoneApps.meta({ Id = "Objetos", Label = "Objetos", Icon = "mochila" }).Name == "Mochila" and PhoneApps.meta({ Id = "Menu", Label = "Menú", Icon = "menu" }).Screen == "Ajustes", "Nombre e icono de app («Objetos» -> «Mochila»; «Menú» -> Ajustes, dentro del teléfono)")
local dock, grid = PhoneApps.layout(calmApps)
check(#dock == 4 and dock[1].Id == "Mapa" and dock[2].Id == "Misiones" and dock[3].Id == "Mensajes" and dock[4].Id == "Menu" and #dock + #grid == #calmApps, "Dock con Mapa, Misiones, Mensajes y Ajustes; el resto en la cuadrícula (ninguna se pierde)")

-- Cada comando de DefaultCommands y cada Hud.addButton del juego está en la lista de arriba y tiene
-- su icono y color de app (si se añade uno nuevo sin pensarlo, esta prueba avisa)
do
	local known = {}
	for _, id in FORMER do
		known[id] = true
	end
	for _, id in { "Mas", "Mensajes", "Cartera", "Ayuda", "AquiMas", "_Volver" } do
		known[id] = true
	end
	local src = fs.readFile("src/client/Commands/DefaultCommands.luau")
	local unknown = {}
	for id in string.gmatch(src, 'Id = "([^"]+)"') do
		if string.sub(id, -1) ~= "_" and not known[id] then
			table.insert(unknown, id)
		end
	end
	check(#unknown == 0, "Todos los comandos de DefaultCommands están contados" .. (if #unknown > 0 then ": nuevos " .. table.concat(unknown, ", ") else ""))
	local noMeta = {}
	local appsFound = 0
	local function walk(dir: string)
		for _, name in fs.readDir(dir) do
			local path = dir .. "/" .. name
			if fs.isDir(path) then
				walk(path)
			elseif string.match(name, "%.luau$") then
				for label in string.gmatch(fs.readFile(path), 'Hud%.addButton%("[^%s"]+%s+([^"]+)"') do
					appsFound += 1
					local id = "App" .. label
					if not PhoneApps.Catalog[id] or not table.find(APPS, id) then
						table.insert(noMeta, id)
					end
				end
			end
		end
	end
	walk("src/client")
	check(appsFound == #APPS and #noMeta == 0, ("Las %d apps de Hud.addButton (Ir a casa, Tienda, Vehículos, Metro…) tienen su icono y color en el ValPhone"):format(appsFound) .. (if #noMeta > 0 then ": " .. table.concat(noMeta, ", ") else ""))
	local passSrc = fs.readFile("src/client/UI/BattlePassUI.luau")
	local passId = string.match(passSrc, 'local ROW_ID = "([^"]+)"')
	check(passId ~= nil and PhoneApps.Catalog[passId] ~= nil, "El pase de temporada es una app con su icono («" .. tostring(passId) .. "»)")
	local missingMeta = {}
	for _, id in { "Objetos", "Mapa", "GestosPase", "ModoPruebas", table.unpack(MORE_CHILDREN) } do
		if not PhoneApps.Catalog[id] then
			table.insert(missingMeta, id)
		end
	end
	check(#missingMeta == 0, "Cada app de siempre tiene su icono y color" .. (if #missingMeta > 0 then ": faltan " .. table.concat(missingMeta, ", ") else ""))
end

print("\n▶ ValPhone: avisos, batería y teclas")
check(PhoneApps.badgeCount({ Badge = true }) == 1 and PhoneApps.badgeCount({ Badge = 3 }) == 3 and PhoneApps.badgeCount({}) == 0, "Punto rojo: true = 1, un número = ese número, nada = 0")
check(PhoneApps.totalBadges(calmApps) == 1, "El numerito del teléfono cerrado suma los avisos de sus apps (el pase: 1)")
local before = { PaseTemporada = 0, Misiones = 0 }
local fresh, after = PhoneApps.newBadges(before, { { Id = "PaseTemporada", Badge = true }, { Id = "Misiones" } })
check(#fresh == 1 and fresh[1].Id == "PaseTemporada" and after.PaseTemporada == 1, "Un punto rojo nuevo (recompensas del pase) baja como aviso")
fresh = PhoneApps.newBadges(after, { { Id = "PaseTemporada", Badge = true } })
check(#fresh == 0, "…una sola vez (no a cada refresco)")
check(PhoneApps.battery(25) == 25 and PhoneApps.battery(0) == 5 and PhoneApps.battery(nil) == 100 and PhoneApps.battery(140) == 100, "Batería = tu energía (mínimo 5 %: «Más batería que nunca»)")
check(PhoneApps.step(1, 10, 4, 0, 1) == 5 and PhoneApps.step(9, 10, 4, 0, 1) == 10 and PhoneApps.step(2, 10, 4, 0, -1) == 1 and PhoneApps.step(10, 10, 4, 1, 0) == 1, "Flechas / cruceta por la cuadrícula de 4 columnas (sin salirse)")

print("\n▶ Mensajes del ValPhone")
local shown = {}
PhoneInbox.setDisplay(function(message)
	table.insert(shown, message.Text)
end)
local changes = 0
PhoneInbox.onChanged(function()
	changes += 1
end)
PhoneInbox.push({ Icon = "📱", From = "Abu Rosa", Text = "Abu Rosa quiere hablar contigo", Open = "Misiones" })
PhoneInbox.push({ Text = "Hola" })
check(PhoneInbox.unread() == 2 and PhoneInbox.list()[1].Text == "Hola" and PhoneInbox.list()[2].Open == "Misiones", "Los mensajes nuevos arriba, sin leer (con a qué app llevan)")
check(#shown == 2 and changes == 2 and PhoneInbox.hasDisplay(), "Cada uno baja como notificación (quien los enseña es el teléfono)")
PhoneInbox.markAllRead()
check(PhoneInbox.unread() == 0 and changes == 3, "Al abrir Mensajes quedan leídos (y el punto rojo se apaga)")
for i = 1, 40 do
	PhoneInbox.push({ Text = "m" .. i })
end
check(#PhoneInbox.list() == 30, "Como mucho 30 mensajes guardados")

print(("\n%s"):format(if failures == 0 then "✅ Todo correcto" else ("❌ %d fallos"):format(failures)))
process.exit(if failures == 0 then 0 else 1)
