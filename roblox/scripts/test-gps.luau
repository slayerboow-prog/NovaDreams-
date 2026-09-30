-- Prueba del GPS (shared/Gps) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-gps.luau
--
-- Comprueba con una ciudad de mentira (una cuadrícula de calles con una T y una diagonal):
--   * el grafo tiene un nodo en cada cruce y en cada T
--   * A* encuentra el camino más corto por las calles (y no atraviesa manzanas)
--   * el principio y el final se pegan a la calle más cercana y el último trozo va recto al sitio
--   * salirse más de 25 studs de la ruta obliga a recalcularla
--   * las indicaciones: izquierda, derecha, recto y "has llegado", según el ángulo
--   * UNA sola guía: la ruta que eliges tú (el aeropuerto) manda sobre la de la misión (indicación,
--     mapas y haz de luz); quitarla o llegar devuelve la de la misión; una misión nueva no la quita

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, Vector2 = roblox.Vector3, roblox.Vector2
local env = setmetatable({ Vector3 = Vector3, Vector2 = Vector2 }, { __index = _G })
local Gps = luau.load(fs.readFile("src/shared/Gps.luau"), { debugName = "Gps", environment = env })()

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function v(x: number, z: number): any
	return Vector3.new(x, 0, z)
end

-- Cuadrícula de 3x3 calles (cada 100 studs) de 0 a 200, cada calle en un solo tramo largo (así los
-- cruces hay que encontrarlos), una calle en T que acaba en la del medio y una diagonal suelta
local segments = {}
for i = 0, 2 do
	table.insert(segments, { A = v(0, i * 100), B = v(200, i * 100) }) -- horizontales
	table.insert(segments, { A = v(i * 100, 0), B = v(i * 100, 200) }) -- verticales
end
table.insert(segments, { A = v(150, 100), B = v(150, 160) }) -- T: acaba encima de la calle z = 100
table.insert(segments, { A = v(200, 200), B = v(300, 300) }) -- diagonal hacia fuera

print("\n▶ Grafo")
local graph = Gps.build(segments)
check(#graph.Nodes == 12, ("Nodos en cruces, T y extremos (%d)"):format(#graph.Nodes))
local function hasNode(x: number, z: number): boolean
	for _, node in graph.Nodes do
		if math.abs(node.X - x) < 0.5 and math.abs(node.Z - z) < 0.5 then
			return true
		end
	end
	return false
end
check(hasNode(100, 100) and hasNode(0, 200) and hasNode(200, 100), "Un nodo en cada cruce de la cuadrícula")
check(hasNode(150, 100), "Y en la T (una calle que acaba encima de otra)")
check(hasNode(300, 300), "Y al final de la diagonal")

print("\n▶ Ruta más corta")
local path = Gps.route(graph, v(5, -8), v(195, 208))
check(path ~= nil, "Hay ruta de una esquina a la otra")
check(path and path[1] == v(5, -8) and path[#path] == v(195, 208), "Empieza donde estás y acaba en el sitio")
local length = path and Gps.length(path) or math.huge
-- (8 hasta la calle + 190 + 200 + 8 = 406: en forma de L o de escalera, nunca en diagonal)
check(math.abs(length - (8 + 190 + 200 + 8)) < 1.5, ("La más corta por las calles (%.1f studs)"):format(length))
local offGrid = false
for _, point in path or {} do
	local onStreet = (point.X % 100 < 0.5 or point.X % 100 > 99.5) or (point.Z % 100 < 0.5 or point.Z % 100 > 99.5)
	if not onStreet and point ~= path[1] and point ~= path[#path] then
		offGrid = true
	end
end
check(not offGrid, "Todos los puntos de en medio están en una calle (no atraviesa manzanas)")

-- Con la diagonal: al final de ella se llega por ella
local far = Gps.route(graph, v(0, 0), v(300, 300))
check(far and math.abs(Gps.length(far) - (400 + math.sqrt(2) * 100)) < 1.5, "Usa la calle en diagonal para llegar al final")

-- Mismo tramo: recto
local same = Gps.route(graph, v(20, 3), v(80, -4))
check(same and #same <= 4 and Gps.length(same) < 70, "Si el sitio está en la misma calle, va recto por ella")

print("\n▶ Pegar a la calle y recalcular")
local snap = Gps.snap(graph, v(47, 12))
check(snap and math.abs(snap.Point.X - 47) < 0.01 and math.abs(snap.Point.Z) < 0.01 and math.abs(snap.Distance - 12) < 0.01, "El punto se pega a la calle más cercana (47, 0)")
local route = Gps.route(graph, v(0, 0), v(200, 0)) :: any
check(not Gps.offRoute(route, v(100, 10)), "A 10 studs de la ruta: sigues en ella")
check(Gps.offRoute(route, v(100, 30)), "A 30 studs (más de 25): hay que recalcular")
local at = Gps.progress(route, v(120, 2))
check(math.abs(at.Remaining - 80) < 0.01, "Lo que queda de ruta (80 studs)")

print("\n▶ Indicaciones")
check(Gps.turnKind(Vector2.new(0, -1), Vector2.new(1, 0)) == "Right", "Hacia el norte y luego al este: derecha")
check(Gps.turnKind(Vector2.new(0, -1), Vector2.new(-1, 0)) == "Left", "Hacia el norte y luego al oeste: izquierda")
check(Gps.turnKind(Vector2.new(0, -1), Vector2.new(0.2, -1)) == nil, "Un cambio pequeño (11°): recto")
check(Gps.turnKind(Vector2.new(1, 0), Vector2.new(1, 1)) == "Right", "45° hacia abajo en el mapa yendo al este: derecha")
local lPath = { v(0, 200), v(0, 100), v(100, 100) } -- norte y luego este
local turn = Gps.nextTurn(lPath, v(0, 180))
check(turn.Kind == "Right" and math.abs(turn.Distance - 80) < 0.01, "Primero: gira a la derecha en 80 studs")
check(Gps.instructionText(turn):find("derecha", 1, true) ~= nil and Gps.instructionText(turn):find("25 m", 1, true) ~= nil, "Texto «Gira a la derecha en 25 m» (" .. Gps.instructionText(turn) .. ")")
turn = Gps.nextTurn(lPath, v(50, 100))
check(turn.Kind == "Straight" and Gps.instructionText(turn) == "Sigue recto", "Pasado el giro: sigue recto")
turn = Gps.nextTurn(lPath, v(95, 100))
check(turn.Kind == "Arrive", "Al final: has llegado")
local lLeft = { v(0, 200), v(0, 100), v(-100, 100) }
check(Gps.nextTurn(lLeft, v(0, 190)).Kind == "Left", "Y a la izquierda si la calle sigue al oeste")
check(Gps.distanceText(350, 16) == "100 m · 1 min", "Distancia y tiempo («" .. Gps.distanceText(350, 16) .. "»)")

print("\n▶ Flechas en el suelo")
local marks = Gps.marks(route, 6, 120, 20)
check(#marks == 20 and marks[1].Direction.X > 0.99, "Hasta 20 flechas en los próximos 120 studs, mirando hacia donde vas")
check(math.abs(marks[2].Position.X - marks[1].Position.X - 6) < 0.01, "Una cada 6 studs")

print("\n▶ Una sola guía: tu ruta manda sobre la de la misión")
do
	local attrs: { [string]: any } = { StoryTarget = v(150, -200) }
	local function get(name: string): any
		return attrs[name]
	end
	local airport = { Position = v(900, 400), Name = "Aeropuerto de Valmar" }
	-- Sin ruta tuya: la misión
	local dest = Gps.pickDestination(nil, get, {})
	check(dest and dest.Name == "Tu misión" and not dest.Manual and dest.Position == v(150, -200), "Sin ruta marcada, el GPS lleva a tu misión («Tu misión»)")
	check(Gps.missionMarker(nil, get) == v(150, -200), "Y el haz de luz y la ★ de los mapas marcan la misión")
	-- Eliges el aeropuerto: manda
	dest = Gps.pickDestination(airport, get, {})
	check(dest and dest.Manual and dest.Name == "Aeropuerto de Valmar" and dest.Position == airport.Position, "Con el aeropuerto marcado, la indicación dice «Aeropuerto de Valmar» (no «Tu misión»)")
	check(Gps.missionMarker(airport, get) == nil, "Y lo de la misión (haz de luz, ★, su ruta) se esconde")
	check(Gps.routeChipText(airport.Name) == "📍 Ruta a Aeropuerto de Valmar", "La tarjeta de la misión dice «" .. Gps.routeChipText(airport.Name) .. "»")
	-- La misión cambia de paso mientras vas al aeropuerto: no te quita la ruta
	attrs.StoryTarget = v(-300, 80)
	dest = Gps.pickDestination(airport, get, {})
	check(dest and dest.Manual and dest.Name == "Aeropuerto de Valmar", "Un paso nuevo de la misión NO quita tu ruta")
	local target, entry = Gps.missionTarget(get, nil)
	local notice = Gps.noticeText(entry, "Ve al instituto")
	check(target == v(-300, 80) and notice == "Nueva misión: Ve al instituto (toca para seguirla)", "Solo avisa: «" .. notice .. "»")
	-- Un trabajo manda sobre la misión (orden de preferencia), pero tampoco sobre tu ruta
	attrs.TaskTarget = v(10, 10)
	check(Gps.pickDestination(nil, get, {}).Name == "Tu trabajo", "Sin ruta tuya, el trabajo va antes que la misión")
	check(Gps.pickDestination(airport, get, {}).Manual, "Con tu ruta, tampoco el trabajo te la quita")
	attrs.TaskTarget = nil
	-- Quitas tu ruta (✕ o «Seguir misión»): vuelve la misión sola
	dest = Gps.pickDestination(nil, get, {})
	check(dest and dest.Name == "Tu misión" and dest.Position == v(-300, 80), "Al quitar tu ruta vuelve sola la de la misión")
	check(Gps.missionMarker(nil, get) == v(-300, 80), "Y su haz de luz y su ★")
	-- Llegar: los sitios del mapa no tienen altura (solo cuenta el plano)
	local manualDest = { Position = v(900, 400), Name = "Aeropuerto de Valmar", Manual = true }
	check(Gps.arrived(manualDest, Vector3.new(905, 40, 402), 14), "Al llegar al aeropuerto (aunque estés más alto) cuenta como llegado")
	check(not Gps.arrived(manualDest, Vector3.new(960, 0, 400), 14), "A 60 studs todavía no")
	check(not Gps.arrived({ Position = Vector3.new(0, 0, 0), Name = "Tu misión", Manual = false }, Vector3.new(3, 50, 0), 14), "Un objetivo de misión a otra altura (otro piso) no cuenta")
	check(Gps.arrivalText("Aeropuerto de Valmar", true) == "📍 Has llegado: Aeropuerto de Valmar · vuelve la ruta de tu misión", "Al llegar: «" .. Gps.arrivalText("Aeropuerto de Valmar", true) .. "»")
	-- Silenciados (✕ sin ruta tuya, o misión ya alcanzada): se salta al siguiente
	attrs.SeasonTarget = v(50, 50)
	dest = Gps.pickDestination(nil, get, { v(-300, 80) })
	check(dest and dest.Name == "Misión de temporada", "Un objetivo silenciado (ya alcanzado o quitado con ✕) deja paso al siguiente")
end

print("\n▶ Una ciudad grande (rendimiento)")
local big = {}
for i = 0, 30 do
	table.insert(big, { A = v(0, i * 60), B = v(1800, i * 60) })
	table.insert(big, { A = v(i * 60, 0), B = v(i * 60, 1800) })
end
local t0 = os.clock()
local bigGraph = Gps.build(big)
local built = os.clock() - t0
t0 = os.clock()
local bigPath = Gps.route(bigGraph, v(3, 3), v(1797, 1790))
local routed = os.clock() - t0
check(#bigGraph.Nodes == 31 * 31, ("Cuadrícula de 31x31: %d nodos"):format(#bigGraph.Nodes))
check(bigPath and math.abs(Gps.length(bigPath) - (3 + 1794 + 1790 + 3 + 3)) < 8, "Ruta correcta de punta a punta")
check(built < 2 and routed < 0.5, ("Rápido: grafo %.2f s, ruta %.3f s"):format(built, routed))

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
