-- Prueba de que no quedan piezas sueltas ni flotando por el mundo, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-props.luau                  # solo las reglas y el código
--   lune run scripts/test-props.luau /tmp/x.rbxl      # y además, el mapa construido (build-place)
--
-- Comprueba que:
--   * el barrendero (shared/LooseParts + SweepService) quita lo suelto que se queda quieto en el suelo
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

local LooseParts = luau.load(fs.readFile("src/shared/LooseParts.luau"), { debugName = "LooseParts" })()

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function info(overrides: { [string]: any }): any
	local base = { Anchored = false, Grounded = false, Person = false, Vehicle = false, Keep = false, Speed = 0, Y = 1 }
	for k, v in overrides do
		base[k] = v
	end
	return base
end

print("Barrendero de piezas sueltas")
local R = LooseParts.RestSeconds
check(R >= 15 and R <= 90, ("lo suelto y quieto se retira en poco rato (%d s)"):format(R))
check(LooseParts.verdict(info({}), R, R) == "Sweep", "un trozo suelto quieto en la calzada se retira")
check(LooseParts.verdict(info({}), R - 5, R - 5) == "Wait", "recién caído, todavía no")
check(LooseParts.verdict(info({ Speed = 20 }), 0, LooseParts.MaxSeconds) == "Sweep", "aunque siga rodando, pasado el máximo se retira")
check(LooseParts.verdict(info({ Y = -1000 }), 0, 0) == "Sweep", "lo que se cae del mapa, enseguida")
check(LooseParts.verdict(info({ Person = true }), 999, 999) == "Keep", "lo que lleva una persona, nunca")
check(LooseParts.verdict(info({ Vehicle = true }), 999, 999) == "Keep", "un vehículo entero (unido a su base), nunca")
check(LooseParts.verdict(info({ Grounded = true }), 999, 999) == "Keep", "lo soldado a algo anclado, nunca")
check(LooseParts.verdict(info({ Anchored = true }), 999, 999) == "Keep", "lo anclado, nunca")
check(LooseParts.verdict(info({ Keep = true }), 999, 999) == "Keep", "lo marcado (juguetes, KeepLoose), nunca")
local rest = 0
for _ = 1, 10 do
	rest = LooseParts.rest(rest, 0.2, 5)
end
check(rest == 50, "quieta: el tiempo quieta se va sumando")
check(LooseParts.rest(rest, 12, 5) == 0, "si se mueve, vuelve a empezar")

print("El código")
local function src(path: string): string
	return fs.readFile(path)
end
local main = src("src/server/Main.server.luau")
check(main:find('"SweepService"', 1, true) ~= nil, "el servidor arranca el barrendero (SweepService)")
local sweep = src("src/server/Services/SweepService.luau")
check(sweep:find("DescendantAdded", 1, true) ~= nil and sweep:find("LooseParts.verdict", 1, true) ~= nil, "el barrendero apunta lo que se crea y lo juzga con LooseParts")
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
