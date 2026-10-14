-- Prueba de la MEMORIA DEL MUNDO y los DECORADOS POR FASE (Lune, fuera de Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-worldmemory.luau
--
-- Comprueba:
--   1. shared/LifeStory/WorldState: claves válidas, valores que se pueden guardar (sin NaN, posiciones
--      como listas, textos cortos), borrar con false, tope de claves, y las condiciones World / NotWorld
--      (también dentro de Conditions.check).
--   2. WorldMemoryService: escribir varias claves, avisos de cambios, réplica al cliente (WorldState y
--      StageSets en JSON, solo si cambia), lo que se GUARDA pasa SaveCheck (lo que acepta el DataStore)
--      y al entrar en OTRO servidor todo sigue igual (consecuencias al volver). La plantilla de
--      DataService trae Story.World.
--   3. Decorados (shared/LifeStory/StageSets): todos bien escritos; el estado sale de la historia
--      (nada → humeante → frío; criatura que se queda a vivir; partidas de antes del motor); los de un
--      jugador llevan su sitio y los de todos solo su estado; el servidor construye los de todos con una
--      variante por estado.
--   4. Dibujos (shared/StageBuilders): cráter, habitante con rutina (se mueve y vuelve) y marca.

local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")

local Instance, Vector3 = roblox.Instance, roblox.Vector3
local CFrame = L.CFrame
local check = L.check

local playerList = {}
L.services.Players = {
	GetPlayers = function()
		return playerList
	end,
	PlayerRemoving = { Connect = function() end },
	PlayerAdded = { Connect = function() end },
}

local WorldState = L.load("src/shared/LifeStory/WorldState")
local Conditions = L.load("src/shared/LifeStory/Conditions")
local StageSets = L.load("src/shared/LifeStory/StageSets")
local StageBuilders = L.load("src/shared/StageBuilders")
local Locations = L.load("src/shared/LifeStory/Locations")
local SaveCheck = L.load("src/shared/SaveCheck")

---------------------------------------------------------------------
print("1. WorldState")
---------------------------------------------------------------------
check(WorldState.validKey("Cielo.Crater.Parque") and not WorldState.validKey("con espacios") and not WorldState.validKey(""), "claves válidas (puntos y letras) y no válidas")
check(WorldState.clean(0 / 0) == nil and WorldState.clean(math.huge) == nil, "NaN e infinito no se guardan")
local pos = WorldState.clean(Vector3.new(1.234, 2, -3.333))
check(type(pos) == "table" and pos[1] == 1.23 and pos[3] == -3.33, "una posición se guarda como lista de números")
check(#WorldState.clean(string.rep("a", 200)) == WorldState.MAX_TEXT, "los textos largos se recortan")
local world = {}
check(WorldState.set(world, "Rex.Vive", true) and world["Rex.Vive"] == true, "se apunta una clave")
check(not WorldState.set(world, "Rex.Vive", true), "apuntar lo mismo no cuenta como cambio")
check(WorldState.set(world, "Rex.Vive", false) and world["Rex.Vive"] == nil, "false la borra")
check(not WorldState.set(world, "mala clave", 1), "una clave mala no se apunta")
local full = {}
for i = 1, WorldState.MAX_KEYS do
	full["K" .. i] = 1
end
check(not WorldState.set(full, "Otra", 1) and WorldState.set(full, "K1", 2), "tope de claves (pero se puede cambiar una que ya está)")
world = { ["Cielo.Crater.Parque"] = "Frio", ["Rex.Vive"] = true }
check(WorldState.matches({ World = { ["Cielo.Crater.Parque"] = "Frio" } }, world), "World: valor exacto")
check(WorldState.matches({ World = { "Rex.Vive" } }, world) and WorldState.matches({ World = { ["Rex.Vive"] = true } }, world), "World: que exista (lista o = true)")
check(not WorldState.matches({ World = { ["Cielo.Crater.Parque"] = "Humeante" } }, world), "World: otro valor no vale")
check(WorldState.matches({ NotWorld = { "Garaje.Cerrado" } }, world) and not WorldState.matches({ NotWorld = { "Rex.Vive" } }, world), "NotWorld")
local ctx = { Stage = "Nino", ClockTime = 12, Weekday = 1, Completed = {}, Flags = {}, Choices = {}, Discovered = {}, World = world }
check(Conditions.check({ World = { ["Rex.Vive"] = true } }, ctx), "Conditions.check entiende World")
local ok, why = Conditions.check({ World = { ["Rex.Vive"] = false } }, ctx)
check(not ok and why == "World", "y explica el motivo (World)")
ctx.World = nil
check(Conditions.check({ NotWorld = { "Rex.Vive" } }, ctx) and not Conditions.check({ World = { "Rex.Vive" } }, ctx), "sin memoria del mundo (partida vieja) no rompe")

---------------------------------------------------------------------
print("2. WorldMemoryService: guardar, replicar y volver a entrar")
---------------------------------------------------------------------
local profiles = {}
local fakeData = {
	get = function(player)
		return profiles[player]
	end,
	onLoaded = function() end,
}
L.mock("src/server/Services/DataService", fakeData)
local function locator(_, def)
	local base = ({ FuenteParque = Vector3.new(300, 0, 0), JuegosColegio = Vector3.new(0, 0, 300), CaminoAlCole = Vector3.new(-300, 0, 0) })[def.Place] or Vector3.zero
	return CFrame.new(base + (def.Offset or Vector3.zero))
end
local World1 = L.load("src/server/Services/WorldMemoryService")
World1._inject(fakeData, locator)

local function profile()
	return { Money = 10, Story = { Version = 1, Completed = {}, Active = {}, Flags = {}, Choices = {}, Discovered = {}, Memories = {}, NpcMemory = {} }, Life = { Stage = "Nino" } }
end
local ana = L.player("Ana", 1)
table.insert(playerList, ana)
profiles[ana] = profile()
local changes = {}
World1.onChanged(function(player, key, value)
	table.insert(changes, { player, key, value })
end)
check(World1.apply(ana, { ["Cielo.Crater.Parque"] = "Humeante", ["Cielo.Crater.Patio"] = "Humeante", ["Mala clave"] = 1 }) == 2, "se apuntan dos claves (la mala no)")
check(type(profiles[ana].Story.World) == "table", "una partida de antes recibe su Story.World")

require("@lune/task").wait(0.01)
check(#changes == 2, "avisa de cada cambio")
check(type(ana.Attributes.WorldState) == "string" and ana.Attributes.WorldState:find("Humeante", 1, true) ~= nil, "réplica: WorldState (JSON) en el jugador")
local sets = serde.decode("json", ana.Attributes.StageSets)
check(sets.CraterParque and sets.CraterParque.S == "Humeante" and sets.CraterParque.P[1] == 297, "réplica: el cráter del parque, humeante y en su sitio (con el desplazamiento del objeto)")
check(sets.CraterCamino == nil, "el del camino aún no (no ha caído)")
local before = ana.Attributes.StageSets
ana.Attributes.StageSets = "x"
World1.publish(ana)
check(ana.Attributes.StageSets == "x", "si nada cambia, no se vuelve a mandar")
ana.Attributes.StageSets = before
World1.set(ana, "Cielo.Crater.Parque", "Frio")
sets = serde.decode("json", ana.Attributes.StageSets)
check(sets.CraterParque.S == "Frio", "al recoger lo que cayó, el cráter se enfría")
World1.set(ana, "Cielo.Chispa", "Parque")
sets = serde.decode("json", ana.Attributes.StageSets)
check(sets.ChispaParque and sets.ChispaParque.S == "Vive", "Chispa se queda a vivir en el cráter")
World1.set(ana, "Pos.Prueba", Vector3.new(1, 2, 3))

-- Guardar como el DataStore (JSON) y entrar en otro servidor
local problems = SaveCheck.scan(profiles[ana])
check(#problems == 0, "lo que se guarda pasa SaveCheck (el DataStore lo acepta)")
local saved = serde.encode("json", profiles[ana])
L.reset("src/server/Services/WorldMemoryService")
local World2 = L.load("src/server/Services/WorldMemoryService")
local profiles2 = {}
local fakeData2 = {
	get = function(player)
		return profiles2[player]
	end,
	onLoaded = function() end,
}
World2._inject(fakeData2, locator)
local ana2 = L.player("Ana", 1)
profiles2[ana2] = serde.decode("json", saved)
World2.publish(ana2)
check(World2.get(ana2, "Cielo.Crater.Parque") == "Frio" and World2.get(ana2, "Cielo.Chispa") == "Parque", "en otro servidor la memoria del mundo sigue igual")
local p = WorldState.toVector(World2.get(ana2, "Pos.Prueba"))
check(p and (p - Vector3.new(1, 2, 3)).Magnitude < 1e-6, "las posiciones vuelven igual")
sets = serde.decode("json", ana2.Attributes.StageSets)
check(sets.CraterParque.S == "Frio" and sets.ChispaParque.S == "Vive" and sets.CraterPatio.S == "Humeante", "al entrar, las consecuencias se ven (decorados publicados)")
local template = fs.readFile("src/server/Services/DataService.luau")
check(template:find("World = {}, -- memoria del mundo", 1, true) ~= nil, "la plantilla de DataService trae Story.World")

---------------------------------------------------------------------
print("3. Decorados por fase")
---------------------------------------------------------------------
local builders = StageBuilders.names()
for id, def in StageSets.Defs do
	local errs = StageSets.check(id, def, { Places = Locations.Places, Builders = builders })
	for _, e in errs do
		print("     " .. e)
	end
	check(#errs == 0, "decorado " .. id)
end
local base = { Stage = "Nino", ClockTime = 12, Weekday = 1, Completed = {}, Flags = {}, Choices = {}, Discovered = {}, World = {} }
local crater = StageSets.Defs.CraterParque
check(StageSets.stateFor(crater, base) == nil, "sin historia: no hay cráter")
base.World["Cielo.Crater.Parque"] = "Humeante"
check(StageSets.stateFor(crater, base) == "Humeante", "cae la estrella: humeante")
base.World["Cielo.Crater.Parque"] = "Frio"
check(StageSets.stateFor(crater, base) == "Frio", "recogido: frío")
local veteran = { Stage = "Adulto", ClockTime = 12, Weekday = 1, Completed = { Saga_02_Grieta = 1 }, Flags = {}, Choices = {}, Discovered = {}, World = {} }
check(StageSets.stateFor(crater, veteran) == "Frio" and StageSets.stateFor(StageSets.Defs.ChispaParque, veteran) == "Vive", "partida de antes del motor (ya hizo Saga_02): cráter frío y Chispa (sin migrar nada)")
local params = StageSets.paramsFor(crater, "Humeante")
check(params.Smoke == true and params.Radius == crater.Params.Radius, "los parámetros del estado se suman a los del decorado")
-- Uno de todos (ficha de prueba): el servidor construye una variante por estado
World2.Defs = {
	Baliza = {
		Scope = "Global",
		Builder = "Marker",
		Position = Vector3.new(5, 0, 5),
		States = { Apagada = { Color = roblox.Color3.new(0.3, 0.3, 0.3) }, Encendida = {} },
		StateFor = { { If = { World = { ["Baliza.On"] = true } }, State = "Encendida" }, { State = "Apagada" } },
	},
	CraterParque = crater,
}
check(#StageSets.check("Baliza", World2.Defs.Baliza, { Builders = builders }) == 0, "un decorado de todos bien escrito")
local globalRoot = Instance.new("Folder")
World2.buildGlobal(globalRoot)
local holder = globalRoot:FindFirstChild("Baliza")
check(holder and holder:FindFirstChild("Apagada") and holder:FindFirstChild("Encendida"), "el servidor lo construye una vez con sus dos variantes")
check(#holder:FindFirstChild("Encendida"):GetDescendants() > 3, "cada variante lleva su dibujo")
local s2 = World2.setsFor(ana2)
check(s2.Baliza and s2.Baliza.S == "Apagada" and s2.Baliza.P == nil, "de todos: al cliente solo le llega el estado (el sitio es fijo)")
World2.set(ana2, "Baliza.On", true)
check(World2.setsFor(ana2).Baliza.S == "Encendida", "y cambia con la historia de cada uno")
check(World2.setsFor(ana2).CraterParque.P ~= nil, "de un jugador: con su sitio")
local scoped = StageSets.resolveAll(World2.Defs, World2.contextOf(ana2), "Global")
check(scoped.Baliza == "Encendida" and scoped.CraterParque == nil, "se pueden pedir por ámbito")

---------------------------------------------------------------------
print("4. Dibujos")
---------------------------------------------------------------------
local folder = Instance.new("Folder")
local built = StageBuilders.build("Crater", folder, CFrame.new(0, 0, 0), { Radius = 3, Glow = true, Smoke = true }, "Medium")
check(built and built.Model and built.Model.Parent == folder, "cráter dibujado")
local resident = StageBuilders.build("Resident", folder, CFrame.new(100, 0, 0), StageSets.paramsFor(StageSets.Defs.ChispaParque, "Vive"), "Medium")
check(resident and resident.Update ~= nil and resident.Model.Name == "Chispa", "Chispa, la habitante del cráter (con rutina)")
local body = resident.Model:FindFirstChild("Cuerpo")
local start = body.CFrame.Position
local farthest, moved = 0, 0
for i = 1, 600 do
	resident.Update(1 / 30, i / 30)
	local here = body.CFrame.Position
	farthest = math.max(farthest, (Vector3.new(here.X, 0, here.Z) - Vector3.new(100, 0, 0)).Magnitude)
	moved = math.max(moved, (here - start).Magnitude)
end
check(moved > 1.5, ("se mueve por su rutina (%.1f studs)"):format(moved))
check(farthest < 4, "sin alejarse de su cráter")
check(StageBuilders.build("Marker", folder, CFrame.new(), {}, "Low") ~= nil, "marca dibujada")
check(StageBuilders.build("NoExiste", folder, CFrame.new(), {}, "Low") == nil, "un dibujo que no existe no rompe")

L.finish("test-worldmemory")
