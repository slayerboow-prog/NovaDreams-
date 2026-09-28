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

print(("\n%s"):format(if failures == 0 then "✅ Todo correcto" else ("❌ %d fallos"):format(failures)))
process.exit(if failures == 0 then 0 else 1)
