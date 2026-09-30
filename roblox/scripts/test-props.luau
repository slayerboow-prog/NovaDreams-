-- Prueba de que no quedan piezas sueltas ni flotando por el mundo, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-props.luau                  # solo las reglas y el código
--   lune run scripts/test-props.luau /tmp/x.rbxl      # y además, el mapa construido (build-place)
--
-- Comprueba que:
--     (o que se cae del mapa) y nunca lo que tiene dueño: personas, vehículos enteros, juguetes…
--   * lo que se tira o se rompe se retira solo: piedras, cristales, puertas (se arreglan)
--   * el tráfico y los peatones (que se copian de modelos en el origen, el cruce grande de Valmar
--     Centro) se ponen en su sitio en cuanto aparecen: nunca se quedan amontonados en el cruce
--   * los iconos de los guardias y limpiadores del metro (🛡️ 🧽) no se ven a través de paredes y techos
--   * en el mapa construido no hay ninguna pieza sin anclar (todo lo del mapa está quieto)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")


local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

print("El código")
local function src(path: string): string
	return fs.readFile(path)
end
local breaks = src("src/server/Services/BreakService.luau")
check(select(2, breaks:gsub("Debris:AddItem%(", "")) >= 3, "piedras caídas, cristales rotos y sonidos se retiran solos (Debris)")
check(breaks:find("repairLater", 1, true) ~= nil, "las puertas que se caen se vuelven a poner solas")
local stone = src("src/client/Controllers/StoneThrow.luau")
check(stone:find("if t > 5 then", 1, true) ~= nil, "la piedra en vuelo se quita como mucho a los 5 s")
local traffic = src("src/client/Controllers/Traffic.luau")
local respawn = traffic:match("local function respawn%(.-\nend\n") or ""
check(respawn:find("setActive(agent, true)\n\t\t\tplace(agent, pose(agent))", 1, true) ~= nil, "cada coche del tráfico se pone en su sitio en cuanto aparece (no en el origen)")
check(traffic:find("pcall(stepAgent", 1, true) ~= nil, "si un coche del tráfico falla, se retira ese (no se paran los demás)")
local ambient = src("src/client/Controllers/Ambient.luau")
local respawnPed = ambient:match("local function respawnPed%(.-\nend\n") or ""
check(respawnPed:find("posePed(agent", 1, true) ~= nil, "cada peatón se pone en su sitio en cuanto aparece (no en el origen)")
local metroLife = src("src/server/Services/MetroLifeService.luau")
local loud = 0
for line in metroLife:gmatch("[^\n]+") do
	if line:find("Npc.icon(", 1, true) and not line:find(", true)", 1, true) then
		loud += 1
	end
end
check(loud == 0, "los iconos del metro (🛡️ 🧽 🗿 👞) solo de cerca y sin verse a través de paredes")
local npc = src("src/server/World/Npc.luau")
check(npc:find("head.Position.Y < UNDERGROUND_Y", 1, true) ~= nil and npc:find("g.AlwaysOnTop = not hidden", 1, true) ~= nil, "bajo tierra (metro) ningún icono de NPC se ve a través de techos y vagones")
local combat = src("src/client/Controllers/CombatController.luau")
check(combat:find("CharacterRemoving", 1, true) ~= nil, "el 🛡 de quien se defiende se quita al reaparecer")

local placePath = process.args[1]
if placePath then
	print("El mapa construido")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local loose, total = {}, 0
	for _, d in game:GetService("Workspace"):GetDescendants() do
		if d:IsA("BasePart") and d.ClassName ~= "Terrain" then
			total += 1
			if not d.Anchored then
				table.insert(loose, d:GetFullName())
			end
		end
	end
	for i = 1, math.min(#loose, 8) do
		print("      suelta: " .. loose[i])
	end
	check(total > 1000, ("hay mapa (%d piezas)"):format(total))
	check(#loose == 0, ("ninguna pieza del mapa sin anclar (%d sueltas)"):format(#loose))
end

print("")
if failures == 0 then
	print("✅ Piezas sueltas: todo correcto")
else
	print(("❌ Piezas sueltas: %d fallos"):format(failures))
	process.exit(1)
end
