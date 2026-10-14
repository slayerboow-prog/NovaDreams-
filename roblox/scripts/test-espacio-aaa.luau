-- Prueba del Espacio «AAA» (fases 2 a 11: docs/espacio-aaa/diseno.md), con Lune (sin Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-espacio-aaa.luau
--
-- Comprueba lo que se puede simular fuera de Roblox:
--   * Vuelo: acelera, frena, freno de emergencia, impulso, lateral, vertical, modos combate/crucero,
--     asistencia e inercia, choques barridos (sin atravesar a mucha velocidad), rebote y recuperación,
--     estaciones sólidas, el margen del servidor.
--   * Teclas: sin teclas repetidas, las nuevas (Espacio sube, F interactúa, X salto, B salir) y que la
--     nave no coge teclas mientras escribes.
--   * (más secciones abajo: HUD, esquiva, hipervelocidad, salto cuántico)
--   * Nave realista de malla «HX-7 Halcón»: respaldo sin ids, triángulos de los archivos exportados,
--     texturas, la misma API con la malla, upgrade, LOD, fallos de carga, compose.luau, la subida sin
--     enseñar la clave y la ficha de la nave.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, Vector2, CFrame = roblox.Vector3, roblox.Vector2, roblox.CFrame

local L = require("./lib/ModuleLoader")

local failures = 0
local function check(ok: any, what: string)
	print((if ok then "  ✅ " else "  ❌ ") .. what)
	if not ok then
		failures += 1
	end
end
local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-3)
end

local ShipFlight = L.load("src/shared/AirCombat/ShipFlight")
local ShipKeys = L.load("src/shared/AirCombat/ShipKeys")
local Zone = L.load("src/shared/Cosmos/Zone")
local Stations = L.load("src/shared/Cosmos/Stations")
local spec = ShipFlight.Specs.Caza

local function input(t: { [string]: any }?): any
	local i = { Pitch = 0, Yaw = 0, Roll = 0 }
	for k, v in t or {} do
		i[k] = v
	end
	return i
end
local function run(s: any, inp: any, seconds: number, env: any?, dt: number?): { string }
	local all = {}
	local step = dt or 1 / 60
	for _ = 1, math.floor(seconds / step + 0.5) do
		for _, e in ShipFlight.advance(s, inp, step, env) do
			table.insert(all, e)
		end
	end
	return all
end
local function has(list: { string }, what: string): boolean
	return table.find(list, what) ~= nil
end
local SPACE = { mode = function()
	return "Space"
end }
local COSMOS = { mode = Zone.modeAt, collide = Zone.collide, bounds = Zone.bounds }

---------------------------------------------------------------------
print("\n🚀 Fase 2 · Vuelo (ShipFlight)")
---------------------------------------------------------------------
do
	-- Responde: acelera y frena
	local s = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	s.Speed = 0
	s.Throttle = 0
	run(s, input({ SetThrottle = 1 }), 0.5, SPACE)
	local early = s.Speed
	run(s, input({ SetThrottle = 1 }), 3, SPACE)
	check(early > 20 and s.Speed > early + 100 and near(s.Speed, spec.MaxSpeed, 3), ("acelera de forma progresiva (%.0f a 0,5 s → %.0f)"):format(early, s.Speed))
	local z0 = s.Pos.Z
	run(s, input({ SetThrottle = 1 }), 1, SPACE)
	check(s.Pos.Z < z0 - 150, "y avanza hacia donde mira el morro")
	run(s, input({ SetThrottle = 1, Brake = true }), 0.4, SPACE)
	check(s.Speed < spec.MaxSpeed - 40 and s.Braking, ("el freno decelera (%.0f)"):format(s.Speed))
	run(s, input({ SetThrottle = 1, EBrake = true }), 1.5, SPACE)
	check(s.Speed < 1 and s.EBraking, ("freno de emergencia: en el espacio se queda quieta (%.1f)"):format(s.Speed))
	run(s, input({ SetThrottle = 1 }), 2, SPACE)
	check(s.Speed > 150, "al soltarlo vuelve a acelerar")
	-- Impulso
	local b = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	run(b, input({ SetThrottle = 1 }), 3, SPACE)
	local before = b.Speed
	run(b, input({ SetThrottle = 1, Boost = true }), 0.8, SPACE)
	check(b.Speed > before + 60 and b.Boosting, ("el impulso sube la velocidad (%.0f → %.0f)"):format(before, b.Speed))
	-- En la atmósfera el freno de emergencia no la para (se hundiría): baja a la mínima
	local at = ShipFlight.new("Caza", CFrame.new(0, 2000, 0), "Atmos")
	run(at, input({ EBrake = true }), 2)
	check(at.Speed >= spec.BrakeSpeed * 0.5 - 1, "en la atmósfera el freno de emergencia no la deja quieta")
end
do
	-- Lateral y vertical (propulsores)
	local s = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	run(s, input({ Strafe = 1 }), 1, SPACE)
	check(s.Pos.X > 30 and s.Rot.LookVector:Dot(Vector3.new(0, 0, -1)) > 0.999, ("lateral a la derecha sin girar el morro (%.0f studs)"):format(s.Pos.X))
	local u = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	run(u, input({ Lift = 1 }), 1, SPACE)
	check(u.Pos.Y > 5030, ("propulsor vertical: sube (%.0f studs)"):format(u.Pos.Y - 5000))
	local d = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	run(d, input({ Lift = -1 }), 1, SPACE)
	check(d.Pos.Y < 4970, "y baja")
end
do
	-- Modos: crucero más rápido, combate gira mejor
	local c = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	ShipFlight.setMode(c, "Cruise")
	run(c, input({ SetThrottle = 1 }), 5, SPACE)
	check(c.Speed > spec.MaxSpeed * 1.3, ("modo crucero: más velocidad máxima (%.0f)"):format(c.Speed))
	local function turned(mode: string): number
		local s = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
		ShipFlight.setMode(s, mode)
		run(s, input({ Yaw = 1, Roll = 0.001 }), 1, SPACE)
		return math.deg(math.acos(math.clamp(s.Rot.LookVector:Dot(Vector3.new(0, 0, -1)), -1, 1)))
	end
	local cb, cr = turned("Combat"), turned("Cruise")
	check(cb > cr * 1.2, ("modo combate gira mejor (%.0f° contra %.0f°)"):format(cb, cr))
end
do
	-- Asistencia e inercia controlada
	local function slide(assist: boolean): number
		local s = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
		ShipFlight.setAssist(s, assist)
		run(s, input({ SetThrottle = 1 }), 3, SPACE)
		run(s, input({ SetThrottle = 1, Yaw = 1, Roll = 0.001 }), 1, SPACE)
		run(s, input({ SetThrottle = 1 }), 0.3, SPACE)
		return s.Drift.Magnitude
	end
	local on, off = slide(true), slide(false)
	check(off > 20 and on < 5, ("sin asistencia la nave derrapa al girar (inercia %.0f), con ella no (%.1f)"):format(off, on))
	local s = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	ShipFlight.setAssist(s, false)
	s.Drift = Vector3.new(40, 0, 0)
	run(s, input(), 1, SPACE)
	local kept = s.Drift.Magnitude
	ShipFlight.setAssist(s, true)
	run(s, input(), 1, SPACE)
	check(kept > 25 and s.Drift.Magnitude < 2, ("la inercia se pierde despacio sin asistencia (%.0f) y deprisa con ella (%.1f)"):format(kept, s.Drift.Magnitude))
end
do
	-- Choques barridos: a la velocidad de la hipervelocidad, con pasos largos, no atraviesa un asteroide
	local rock = Zone.rocks()[1]
	local start = rock.Center + Vector3.new(0, 0, rock.Radius + 400)
	local s = ShipFlight.new("Caza", CFrame.new(start), "Space")
	s.Override = { Speed = 1500, Accel = 5000, Decel = 5000, Turn = 0.25 }
	s.Speed = 1500
	local ev = run(s, input(), 1, COSMOS, 0.1)
	check(has(ev, "Crash") and s.Crashed == "un asteroide" and s.Pos.Z > rock.Center.Z - rock.Radius, ("a 1500 studs/s y 0,1 s por paso choca con el asteroide (no lo atraviesa: Z %.0f)"):format(s.Pos.Z - rock.Center.Z))
	-- Rebote suave contra una estación (ahora sólida) y recuperación
	local st = Stations.List[1]
	local hull = Stations.hulls(st)[1]
	local p = hull.Center + Vector3.new(hull.Half.X + 30, 0, 0)
	local r = ShipFlight.new("Caza", CFrame.new(p) * CFrame.Angles(0, math.rad(90), 0), "Space")
	r.Speed = 60
	r.Throttle = 0
	ev = run(r, input({ SetThrottle = 0 }), 2, { mode = Zone.modeAt, collide = Zone.collide })
	check(has(ev, "Bump") and not r.Crashed and r.Bumped == "una estación", "despacio contra una estación: rebota (no estalla)")
	check(Stations.hullHit(r.Pos, spec.Radius) == nil, "y se queda fuera del casco")
	check(r.RecoverUntil > 0, "y se endereza sola un momento (recuperación)")
	local fast = ShipFlight.new("Caza", CFrame.new(p) * CFrame.Angles(0, math.rad(90), 0), "Space")
	fast.Speed = 300
	ev = run(fast, input({ SetThrottle = 1 }), 1, { mode = Zone.modeAt, collide = Zone.collide })
	check(has(ev, "Crash") and fast.Crashed == "una estación", "deprisa contra una estación: estalla")
	check(Zone.collide(Stations.launch(st).Position, spec.Radius) == nil, "la salida del muelle está libre (no choca al despegar)")
	-- Rebote contra el suelo despacio (también la superficie de un planeta: misma regla)
	local g = ShipFlight.new("Caza", CFrame.new(-4000, 8, -4000) * CFrame.Angles(math.rad(-30), 0, 0), "Atmos")
	g.Speed = 70
	ev = run(g, input({ SetThrottle = 0 }), 1, { mode = Zone.modeAt, collide = Zone.collide })
	check(has(ev, "Bump") and not g.Crashed, "rozar el suelo despacio: rebote y recuperación")
end
do
	-- Margen del servidor: solo con lo que el servidor ha aprobado
	local a = Vector3.zero
	check(ShipFlight.plausible(spec, a, Vector3.new(0, 0, -spec.MaxSpeed * 1.45 / 20), 1 / 20), "el servidor admite el modo crucero")
	check(not ShipFlight.plausible(spec, a, Vector3.new(0, 0, -1500 / 20), 1 / 20), "pero no la hipervelocidad sin aprobarla")
	check(ShipFlight.plausible(spec, a, Vector3.new(0, 0, -1500 / 20), 1 / 20, 1600), "con la hipervelocidad aprobada, sí")
	local s = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	ShipFlight.setMode(s, "Cruise")
	run(s, input({ SetThrottle = 1, Boost = true, Strafe = 1, Lift = 1 }), 2, SPACE)
	local p0 = s.Pos
	run(s, input({ SetThrottle = 1, Boost = true, Strafe = 1, Lift = 1 }), 1 / 20, SPACE)
	check(ShipFlight.plausible(spec, p0, s.Pos, 1 / 20), "todo a la vez (crucero, impulso, lateral y vertical) sigue siendo válido para el servidor")
end

---------------------------------------------------------------------
print("\n⌨️ Teclas (ShipKeys)")
---------------------------------------------------------------------
do
	local clash = ShipKeys.conflicts()
	check(#clash == 0, "ninguna tecla en dos acciones" .. (if #clash > 0 then ": " .. table.concat(clash, ", ") else ""))
	check(ShipKeys.actionFor("Space") == "Up" and ShipKeys.actionFor("F") == "Interact" and ShipKeys.actionFor("X") == "Quantum" and ShipKeys.actionFor("B") == "Exit", "Espacio sube, F interactúa, X salto cuántico, B salir")
	check(ShipKeys.actionFor("C") == "Dodge" and ShipKeys.actionFor("Z") == "Cloak" and ShipKeys.actionFor("R") == "Reload" and ShipKeys.actionFor("LeftShift") == "Boost" and ShipKeys.actionFor("LeftControl") == "Brake", "C esquiva, Z camuflaje, R recargar, Shift impulso, Ctrl freno")
	check(ShipKeys.actionFor("MouseButton1") == "Fire" and ShipKeys.actionFor("MouseButton2") == "Precision", "clic izquierdo dispara, clic derecho precisión")
	local codes = ShipKeys.keyCodes()
	check(table.find(codes, "One") and table.find(codes, "Eight") and not table.find(codes, "F") and not table.find(codes, "V"), "a los mandos, la nave se queda 1-8 (no equipan la barra rápida) y deja F/V a su controlador")
	check(not ShipKeys.remap("Mode", { "C" }) and ShipKeys.remap("Mode", { "N" }) and ShipKeys.actionFor("N") == "Mode", "se puede reasignar (sin pisar otra acción)")
	ShipKeys.remap("Mode", { "T" })
	check(ShipKeys.label("Boost") == "Shift" and ShipKeys.label("Boost", "Gamepad") == "LB" and #ShipKeys.hints("Keyboard") >= 10, "pistas de teclas (ordenador) y botones (mando)")
	-- La nave no coge teclas mientras escribes en el chat
	local src = fs.readFile("src/client/Controllers/AirCombatClient.luau")
	local onKey = string.match(src, "local function onKey%(.-\nend\n") or ""
	local readIn = string.match(src, "local function readInput%(.-\nend\n") or ""
	check(string.find(onKey, "if typing() then", 1, true) ~= nil and string.find(onKey, "ContextActionResult.Pass", 1, true) ~= nil, "escribiendo en el chat, las teclas pasan al chat (onKey)")
	check(string.find(readIn, "not isTyping", 1, true) ~= nil, "y la nave no lee el teclado (readInput)")
	local spaceSrc = fs.readFile("src/client/Controllers/SpaceClient.luau")
	check(string.find(spaceSrc, "GetFocusedTextBox", 1, true) ~= nil, "lo mismo con V/F/G del espacio (SpaceClient)")
end

---------------------------------------------------------------------
print("\n🖥️ Fase 3 · HUD por zonas (UI/ShipHudLayout, UI/AirCombatHud) y mandos")
---------------------------------------------------------------------
L.services.TweenService = { Create = function()
	return { Play = function() end }
end }
L.services.UserInputService = { TouchEnabled = false, KeyboardEnabled = true, GamepadEnabled = false }
L.services.GuiService = { GetGuiInset = function()
	return Vector2.new(0, 58)
end }
L.workspace = { CurrentCamera = { ViewportSize = Vector2.new(932, 430) } }
local SHL = L.load("src/client/UI/ShipHudLayout")
local ShipAbilities = L.load("src/shared/AirCombat/ShipAbilities")
local NavInfo = L.load("src/shared/Cosmos/NavInfo")
do
	for _, case in { { 1920, 1080, false }, { 932, 430, true }, { 844, 390, true }, { 640, 360, true } } do
		local w, h, touch = case[1], case[2], case[3]
		local l = SHL.compute(Vector2.new(w, h), { Touch = touch, Inset = 58 })
		local clash = SHL.clashes(l)
		check(#clash == 0, ("%dx%d: ninguna zona se pisa (ni con los botones ni con la palanca)%s"):format(w, h, if #clash > 0 then ": " .. table.concat(clash, ", ") else ""))
		local center = SHL.center(l)
		local covering = {}
		for name, r in l.Zones do
			if not SHL.Overlays[name] and SHL.overlaps(r, center) then
				table.insert(covering, name)
			end
		end
		check(#covering == 0, ("%dx%d: el centro (la mira y el combate) queda libre%s"):format(w, h, if #covering > 0 then ": " .. table.concat(covering, ", ") else ""))
		local need = if w == 640 then 32 else 44
		local slotPt = l.SlotSize * l.Scale
		if touch then
			check(slotPt >= need, ("%dx%d: las 8 ranuras se pueden tocar (%d pt)"):format(w, h, math.floor(slotPt)))
			check(l.Zones.Keys == nil and l.Zones.Moves == nil and l.Zones.Quick == nil and l.Zones.Ship == nil and l.Zones.Help ~= nil, ("%dx%d: en el móvil, sin listas de teclas (palanca y botones; «?» para la ayuda)"):format(w, h))
			check(l.Buttons.Fuego and l.Buttons.EsquivaNave and l.Buttons.Fuego.W >= l.Buttons.Misil.W and l.Buttons.Fuego.W >= l.Buttons.EsquivaNave.W, ("%dx%d: DISPARO es el botón más grande; ESQUIVA tiene su hueco"):format(w, h))
		else
			check(l.Zones.Keys ~= nil and l.Zones.Moves ~= nil and l.Zones.Ship ~= nil and l.Zones.Quick ~= nil and l.Stick == nil, ("%dx%d: en el ordenador, las dos listas de teclas, la nave en planta, los atajos y sin palanca táctil gigante"):format(w, h))
		end
		local d, e = l.Zones.D, l.Zones.E
		check(d.X + d.W <= l.Canvas.X and e.Y >= d.Y + d.H and e.X + e.W <= l.Canvas.X, ("%dx%d: radar arriba a la derecha y misiones debajo"):format(w, h))
		-- TODO lo de la imagen de referencia tiene su zona (en el móvil, en compacto)
		local missing = {}
		for _, n in { "A", "B", "D", "E", "J", "Speed", "Defense", "Jump", "Target", "H", "Prompt" } do
			if not l.Zones[n] then
				table.insert(missing, n)
			end
		end
		check(#missing == 0, ("%dx%d: perfil, brújula, radar, misiones, velocidad, escudo/estructura, salto, objetivo, ranuras y letrero%s"):format(w, h, if #missing > 0 then ": faltan " .. table.concat(missing, ", ") else ""))
		local sp, df, c = l.Zones.Speed, l.Zones.Defense, SHL.center(l)
		check(sp.X + sp.W <= c.X and df.X >= c.X + c.W, ("%dx%d: velocidad a la izquierda de la mira y escudo/estructura a la derecha"):format(w, h))
		-- Por vehículo: el avión, sin salto cuántico (y sin pisarse)
		local pl = SHL.compute(Vector2.new(w, h), { Touch = touch, Inset = 58, Vehicle = "Plane" })
		local pclash = SHL.clashes(pl)
		check(pl.Zones.Jump == nil and pl.Zones.Quantum == nil and pl.Zones.Speed ~= nil and #pclash == 0, ("%dx%d: el avión usa el mismo HUD sin el salto cuántico%s"):format(w, h, if #pclash > 0 then ": " .. table.concat(pclash, ", ") else ""))
	end
	SHL.defineVehicle("Prueba", { Name = "COCHE VOLADOR", Without = { "Jump", "Quantum", "Moves" }, Shield = false })
	local custom = SHL.compute(Vector2.new(1920, 1080), { Vehicle = "Prueba" })
	check(custom.Zones.Moves == nil and custom.Zones.Keys ~= nil and SHL.vehicle("Prueba").Name == "COCHE VOLADOR" and SHL.vehicle("Nada").Name == "NAVE", "otros vehículos se añaden con defineVehicle (sus zonas y si tienen escudo)")
	SHL.Vehicles.Prueba = nil
	-- Arcos: rayitas a lo largo del arco (velocidad: de abajo a arriba por la izquierda)
	local ticks = SHL.arc(10, 110, 250, 0.46)
	check(#ticks == 10 and ticks[1].X < 0.5 and ticks[1].Y > 0.5 and ticks[10].Y < 0.5 and ticks[10].X < 0.5, "arco de velocidad: 10 rayitas, de abajo a arriba por la izquierda")
	check(SHL.lit(20, 0.5) == 10 and SHL.lit(20, 1.4) == 20 and SHL.lit(20, -1) == 0, "se encienden las que tocan (con tope)")
	-- Teclas en dos listas (como la referencia), con mando sus botones
	local flight = ShipKeys.groupHints("Flight", "Keyboard")
	local special = ShipKeys.groupHints("Special", "Keyboard")
	local function hasKey(list: { any }, key: string, text: string): boolean
		for _, h in list do
			if h.Key == key and string.find(h.Text, text, 1, true) then
				return true
			end
		end
		return false
	end
	check(hasKey(flight, "W/S", "Motor") and hasKey(flight, "Shift", "Impulso") and hasKey(flight, "Ctrl", "Frenar") and hasKey(flight, "Q", "Giro izquierda") and hasKey(flight, "E", "Giro derecha") and hasKey(flight, "R", "Recargar") and hasKey(flight, "F", "Interactuar"), "COMANDOS DE VUELO: motor, impulso, freno, giros, recargar, interactuar")
	check(hasKey(special, "C", "Esquivar") and hasKey(special, "X", "Salto") and hasKey(special, "Z", "Camuflaje") and hasKey(special, "8", "Dron") and hasKey(special, "B", "Salir"), "MANIOBRAS ESPECIALES: esquivar, salto, camuflaje, dron, salir")
	local padSpecial = ShipKeys.groupHints("Special", "Gamepad")
	check(hasKey(padSpecial, "A", "Esquivar") and hasKey(padSpecial, "Select", "Salto") and not hasKey(padSpecial, "Z", "Camuflaje"), "con mando: sus botones (lo que no tiene botón no sale)")
	check(#flight <= SHL.KeyRows.Keys and #special <= SHL.KeyRows.Moves and ShipKeys.actionFor("H") == "Help" and #ShipKeys.conflicts() == 0, "caben en sus listas; H las pliega (sin repetir teclas)")
	-- Brújula: gira con el rumbo real
	local function markAt(marks: { any }, text: string): number?
		for _, m in marks do
			if m.Text == text then
				return m.X
			end
		end
		return nil
	end
	check(near(NavInfo.heading(Vector3.new(0, 0, -1)), 0) and near(NavInfo.heading(Vector3.new(1, 0, 0)), 90) and near(NavInfo.heading(Vector3.new(0, 0, 1)), 180), "rumbo: hacia -Z es el norte (0°), +X el este (90°)")
	local north = SHL.compass(0)
	check(near(markAt(north, "N") or -1, 0.5) and markAt(north, "S") == nil, "brújula mirando al norte: N en el centro, S fuera")
	local east = SHL.compass(NavInfo.heading(CFrame.Angles(0, math.rad(-90), 0).LookVector))
	check(near(markAt(east, "E") or -1, 0.5, 0.01) and (markAt(east, "NE") or 1) < 0.5 and markAt(east, "N") == nil, "girando a la derecha (este): E en el centro, NE a la izquierda y la N fuera")
	local ne = SHL.compass(45)
	check((markAt(ne, "N") or 1) < 0.5 and (markAt(ne, "E") or 0) > 0.5 and near(markAt(ne, "NE") or -1, 0.5), "a 45°: NE en el centro, N a la izquierda, E a la derecha")
	check(SHL.bearingX(0, 30) ~= nil and SHL.bearingX(0, 30) > 0.5 and SHL.bearingX(0, 170) == nil, "el rombo del destino sale donde está (o no sale si queda detrás)")
	-- Radar: delante = arriba, y solo lo que está dentro del alcance
	local ship = CFrame.new(0, 5000, 0)
	local blips = SHL.blips(ship, {
		{ Kind = "Estacion", Pos = Vector3.new(0, 5000, -3000) },
		{ Kind = "Enemigo", Pos = Vector3.new(0, 5000, -700), Id = "e1" },
		{ Kind = "Campo", Pos = Vector3.new(2000, 5000, 0), Radius = 900 },
		{ Kind = "Aliado", Pos = Vector3.new(-300, 5100, 0) },
	}, 1400)
	local kinds = {}
	for _, b in blips do
		kinds[b.Kind] = b
	end
	check(kinds.Enemigo and kinds.Enemigo.Point.Y < -0.4 and near(kinds.Enemigo.Point.X, 0), "radar: el enemigo delante sale arriba")
	check(kinds.Estacion == nil, "radar: la estación a 3000 no sale con alcance 1400 (fuera de detección)")
	check(kinds.Campo and kinds.Campo.Point.X > 0.9, "radar: un campo de asteroides cuenta desde su borde (sale a la derecha)")
	check(kinds.Aliado and kinds.Aliado.Point.X < 0 and kinds.Aliado.Above > 0, "radar: otro piloto a la izquierda y por encima")
	check(blips[1].Kind == "Enemigo", "radar: los enemigos primero")
	local far = SHL.blips(ship, { { Kind = "Estacion", Pos = Vector3.new(0, 5000, -3000) } }, 4000)
	check(#far == 1 and far[1].Point.Y < -0.7, "en modo crucero el radar llega más lejos (4000): la estación sí sale")
	-- Ranuras: estado de cada una (conectadas al equipamiento real)
	local views = ShipAbilities.slotViews({ Energy = 100, Weapon = "Laser", Missiles = 4, Cool = { Quantum = 6 }, Hyper = nil })
	check(#views == 8 and views[1].Key == "1" and views[8].Key == "8", "8 ranuras con su tecla (1-8)")
	check(views[4].State == "Ready" and views[5].State == "Ready" and views[8].State == "Locked" and views[8].Note == "Desbloquear en estación", "segunda tanda: escudo especial y camuflaje ya funcionan; el dron, bloqueado hasta desbloquear uno (con el motivo)")
	local withDrone = ShipAbilities.slotViews({ Energy = 100, Cool = {}, DroneKind = "Defensa" })
	check(withDrone[8].State == "Ready", "con un dron desbloqueado, la ranura 8 se puede usar")
	check(views[3].Selected and not views[1].Selected and views[2].Count == "4" and views[1].Count == "∞", "láser elegido, misiles con su cantidad")
	check(views[6].State == "Cooling" and views[6].Cool > 0.4, "salto cuántico en recarga (con lo que falta)")
	local low = ShipAbilities.slotViews({ Energy = 10, Missiles = 0, MissileReload = 0.25, Cool = {}, HyperBlock = nil })
	check(low[7].State == "NoEnergy" and low[6].State == "NoEnergy" and low[2].State == "Cooling", "sin energía: hipervelocidad y salto avisan; sin misiles: recargando")
	local busy = ShipAbilities.slotViews({ Energy = 80, Cool = {}, Hyper = "Travel", Quantum = nil, QuantumBlock = "Combate" })
	check(busy[7].State == "Active" and busy[6].State == "Blocked" and busy[6].Note == "En combate", "hipervelocidad activa; salto bloqueado en combate (con el motivo)")
end
do
	-- El HUD de verdad (instancias), con valores del servidor
	local Hud = L.load("src/client/UI/AirCombatHud")
	local pg = roblox.Instance.new("Folder")
	local ok, view = pcall(Hud.new, pg, false)
	check(ok and view and pg:FindFirstChild("AirCombatHud") and pg:FindFirstChild("AirCombatOverlay"), "el HUD de la nave se construye (zonas A-J y la capa de la mira)" .. (if ok then "" else ": " .. tostring(view)))
	if ok then
		local zones = {}
		for _, n in { "A", "B", "D", "E", "H", "J", "Prompt", "Quantum", "Speed", "Defense", "Jump", "Target", "Keys", "Moves", "Ship", "Quick" } do
			if not view.Zones[n] then
				table.insert(zones, n)
			end
		end
		check(#zones == 0, "todas las zonas existen" .. (if #zones > 0 then ": faltan " .. table.concat(zones, ", ") else ""))
		Hud.set(view, { Speed = 284.4, Boost = 0.5, BoostReady = true, Shield = 30, MaxShield = 60, Hull = 25, MaxHull = 100, Missiles = 3, MaxMissiles = 6, Overheated = false, Wave = 0, Score = 0, Objective = "Vuelo libre", Mode = "Space", Energy = 55, MaxEnergy = 100, Weapon = "Laser", Heat = 0.4, FlightMode = "Cruise", Assist = false })
		local V = view.Values
		check(V.Speed.Text == "284" and V.Shield.Text == "50%" and V.Hull.Text == "25%" and V.ShipShield.Text == "50%" and V.Missiles.Text == "3/6" and V.Energy.Text == "55%" and V.Weapon.Text == "LÁSER", "el HUD enseña lo que manda el servidor (escudo y estructura en %, misiles, energía, arma)")
		local litSpeed, litShield = 0, 0
		for _, f in view.Arcs.Speed do
			if f.BackgroundTransparency < 0.5 then
				litSpeed += 1
			end
		end
		for _, f in view.Arcs.Shield do
			if f.BackgroundTransparency < 0.5 then
				litShield += 1
			end
		end
		check(litSpeed > 0 and litSpeed < #view.Arcs.Speed and litShield == #view.Arcs.Shield / 2, "arcos: velocidad a medias y escudo a la mitad")
		check(near(view.Bars.MiniShield.Size.X.Scale, 0.5) and near(view.Bars.MiniHull.Size.X.Scale, 0.24, 0.02) and near(view.Bars.MiniEnergy.Size.X.Scale, 0.56, 0.02), "barras pequeñas del perfil: casco, escudo y energía")
		check(view.Chips.Combat.Text == "OFF", "«Modo Combate» OFF en crucero")
		check(near(view.Bars.Shield.Size.X.Scale, 0.5) and near(view.Bars.Energy.Size.X.Scale, 0.56, 0.02) and view.Bars.Hull.BackgroundColor3.R > view.Bars.Hull.BackgroundColor3.G, "barras al valor (y el casco crítico en rojo)")
		check(view.Chips.Mode.Text == "CRUCERO · LIBRE", "modo de vuelo y asistencia a la vista")
		Hud.setProfile(view, { UserId = 1, Name = "Piloto", Level = 12, Money = "$4.200", Chispas = 7 })
		check(view.Profile.Name.Text == "Piloto" and view.Profile.Level.Text == "Nv. 12" and view.Profile.Chispas.Text == "✨ 7" and string.find(view.Profile.Avatar.Image, "AvatarHeadShot", 1, true) ~= nil, "perfil: avatar real, nombre, nivel, dinero y Chispas")
		Hud.setProfile(view, { UserId = 1, Name = "Piloto", Level = 12, Money = "$4.200", Chispas = 7, Resources = { { Text = "⛏ 3/40" }, { Text = "💎 2" } } })
		check(view.Profile.Res[2].Text == "⛏ 3/40" and view.Profile.Res[3].Text == "💎 2", "perfil: los 3 recursos (Chispas, bodega y cristales)")
		Hud.setClock(view, "14:27")
		check(view.Clock and view.Clock.Text == "14:27", "reloj abajo a la derecha")
		Hud.setTarget(view, nil)
		check(view.TargetCard.Empty.Visible and not view.TargetCard.Name.Visible, "OBJETIVO: sin blanco, dice cómo elegir uno")
		Hud.setTarget(view, { Name = "Caza", Level = 3, Health = 0.7, Dist = "1,2 km", Locked = true })
		check(view.TargetCard.Name.Text == "Caza" and view.TargetCard.Level.Text == "Nv. 3" and near(view.TargetCard.Bar.Size.X.Scale, 0.7) and string.find(view.TargetCard.Dist.Text, "FIJADO", 1, true) ~= nil, "OBJETIVO: nombre, nivel, salud y distancia")
		Hud.setLock(view, true, { Name = "Caza", Level = 3, Health = 0.4, Dist = "1,2 km" })
		check(#view.Brackets == 8 and view.Brackets[1].BackgroundColor3.R > 0.9 and view.Brackets[1].BackgroundColor3.G < 0.3 and string.find(view.LockInfo.Text, "Nv. 3", 1, true) ~= nil and near(view.LockHealth.Size.X.Scale, 0.4) and view.LockDist.Text == "1,2 km", "corchetes de fijación con nombre, nivel, salud y distancia")
		Hud.setJump(view, { Dest = "Estación Cénit", Info = "2,4 km · SALTO LISTO (X)" })
		check(view.Jump.Dest.Text == "Destino: Estación Cénit" and string.find(view.Jump.Info.Text, "2,4 km", 1, true) ~= nil, "SALTO CUÁNTICO: destino, distancia y cómo activarlo")
		Hud.setHintGroups(view, "Keyboard")
		local function rowsOf(list: any): number
			local n = 0
			for _, c in list:GetChildren() do
				if c:IsA("Frame") then
					n += 1
				end
			end
			return n
		end
		check(rowsOf(view.Hints) >= 10 and rowsOf(view.HintsSpecial) >= 8 and view.QuickRows.Dodge.Text == "C" and view.QuickRows.Cloak.Text == "Z", "COMANDOS DE VUELO y MANIOBRAS ESPECIALES llenas; atajos con su tecla")
		Hud.toggleHints(view)
		check(not view.HintsOpen and not view.Hints.Visible and view.Zones.Keys.Size.Y.Offset == 30, "H pliega las listas (queda el título)")
		Hud.toggleHints(view)
		check(view.HintsOpen and view.Hints.Visible and view.Zones.Keys.Size.Y.Offset > 30, "y las vuelve a abrir")
		Hud.setHintGroups(view, "Gamepad")
		check(view.QuickRows.Dodge.Text == "A", "con mando: los atajos enseñan sus botones")
		Hud.setVehicle(view, "Plane")
		check(not view.Zones.Jump.Visible and view.Zones.Speed.Visible and not view.ShieldRows[1].Visible, "avión: sin salto cuántico ni escudo (el resto igual)")
		Hud.setVehicle(view, "Ship")
		check(view.Zones.Jump.Visible and view.ShieldRows[1].Visible, "y la nave lo vuelve a tener")
		Hud.setCompass(view, 90, 120)
		local centerText = nil
		for _, m in view.Nav.Marks do
			if m.Label.Visible and near(m.Label.Position.X.Scale, 0.5, 0.01) then
				centerText = m.Label.Text
			end
		end
		check(centerText == "E" and view.Nav.Target.Visible and view.Nav.Target.Position.X.Scale > 0.5, "brújula: mirando al este sale E en el centro y el destino a la derecha")
		Hud.setNav(view, { Zone = "Cinturón de Hierro", Detail = "Campo de asteroides", Dest = "▶ Estación Alba · 1,2 km", Quantum = "SALTO LISTO (X)" })
		check(string.find(view.Nav.Zone.Text, "Cinturón", 1, true) ~= nil and view.Nav.System.Text == "◆ Sistema Valmar", "navegación: «Sistema Valmar», la zona y el destino")
		Hud.setSlots(view, ShipAbilities.slotViews({ Energy = 100, Missiles = 6, Cool = {} }), "Keyboard")
		local s8 = view.Slots[8]
		check(s8.Lock.Visible and s8.Name.Text == "Desbloquear en estación" and not view.Slots[4].Lock.Visible and not view.Slots[1].Lock.Visible and view.Slots[2].Count.Text == "6", "barra: solo el dron sin desbloquear lleva candado (con el motivo); las demás con su cantidad")
		local blips = SHL.blips(CFrame.new(0, 5000, 0), { { Kind = "Enemigo", Pos = Vector3.new(0, 5000, -500) }, { Kind = "Estacion", Pos = Vector3.new(400, 5000, 0) } }, 1400)
		Hud.radar(view, blips, 1400, 90)
		check(view.RadarLetters.E.Position.Y.Scale < 0.1 and view.RadarLetters.N.Position.X.Scale < 0.1, "radar: N/E/S/O giran con el rumbo (mirando al este, E arriba)")
		local shown = 0
		for _, b in view.Blips do
			if b.Visible then
				shown += 1
			end
		end
		check(shown == 2 and view.Blips[1].BackgroundColor3.R > 0.9, "radar: un punto por cosa detectada, el enemigo en rojo")
		Hud.setMissions(view, { { Kind = "PRINCIPAL", Title = "Saga 2", Step = "Ve a Tefra", Right = "12 km" }, { Kind = "EVENTO", Title = "⚠ Patrulla" } })
		check(view.Missions[1].Row.Visible and view.Missions[1].Title.Text == "Saga 2" and view.Missions[2].Kind.Text == "EVENTO" and not view.Missions[3].Row.Visible, "misiones: principal y evento, con distancia")
		Hud.setCompass(view, 0, nil, { { Bearing = 20, Color = roblox.Color3.fromRGB(255, 0, 0) }, { Bearing = 170 } })
		check(view.Nav.Extra[1].Visible and view.Nav.Extra[1].Position.X.Scale > 0.5 and not view.Nav.Extra[2].Visible, "brújula: otras marcas (objetivo, misión) donde están")
		Hud.showQuantum(view, { { Id = "Estacion_Cenit", Name = "Estación Cénit", Kind = "Estación", Dist = "2 km", Cost = 30, Ok = true }, { Id = "Campo_Brasa", Name = "Campo Brasa", Kind = "Campo", Dist = "1 km", Cost = 26, Ok = false, Reason = "Sin descubrir" } }, "Energía 80", function() end, function() end)
		check(Hud.quantumOpen(view) and #view.Quantum.Rows == 2, "selector del salto: lista de destinos con distancia y coste")
		Hud.hideQuantum(view)
		check(not Hud.quantumOpen(view), "y se cierra")
		local texts = Hud.texts({ Speed = 0, Boost = 0, BoostReady = true, Shield = 0, MaxShield = 60, Hull = 0, MaxHull = 100, Missiles = 0, MaxMissiles = 6, Overheated = false, Wave = 0, Score = 0, Objective = "", Mode = "Space", Alert = "⚔ EN COMBATE" })
		check(texts.Warning == "⚔ EN COMBATE", "avisos (zona J) solo cuando hacen falta")
	end
	-- Móvil: el mismo HUD en compacto, con «?» para la ayuda
	local pgT = roblox.Instance.new("Folder")
	local okT, viewT = pcall(Hud.new, pgT, true)
	check(okT and viewT.Zones.Help and viewT.HelpPanel and not viewT.HelpPanel.Visible and viewT.Clock ~= nil and viewT.Zones.Keys == nil, "móvil: sin listas de teclas; «?» con la ayuda y el reloj en el perfil" .. (if okT then "" else ": " .. tostring(viewT)))
	if okT then
		Hud.toggleHelp(viewT)
		check(viewT.HelpPanel.Visible, "«?» abre la ayuda de los botones")
		Hud.toggleHelp(viewT, false)
		Hud.set(viewT, { Speed = 100, Boost = 1, BoostReady = true, Shield = 60, MaxShield = 60, Hull = 100, MaxHull = 100, Missiles = 6, MaxMissiles = 6, Overheated = false, Wave = 0, Score = 0, Objective = "", Mode = "Space", Energy = 100, MaxEnergy = 100 })
		check(viewT.Values.Shield.Text == "100%" and viewT.Values.Energy.Text == "100%", "móvil: los mismos valores")
	end
	-- Eventos globales (con su reloj, iguales para todos: hora del servidor)
	local SpaceEvents = L.load("src/shared/Cosmos/SpaceEvents")
	local e0 = SpaceEvents.at(10)
	local e1 = SpaceEvents.at(SpaceEvents.Active + 10)
	check(e0.Active and near(e0.Left, SpaceEvents.Active - 10) and not e1.Active and e1.Id ~= e0.Id and near(e1.Left, SpaceEvents.Cycle - SpaceEvents.Active - 10), "evento global: 5 min en marcha y luego cuenta atrás al siguiente")
	local t0, s0 = SpaceEvents.texts(e0)
	local t1, s1 = SpaceEvents.texts(e1)
	check(string.find(t0, e0.PlaceName, 1, true) ~= nil and string.find(s0, "Termina en 04:50", 1, true) ~= nil and string.find(t1, "Próximo", 1, true) ~= nil and string.find(s1, "Empieza en", 1, true) ~= nil, ("textos con reloj: «%s · %s»"):format(t0, s0))
	local storm, raid
	for i = 0, 7 do
		local ev = SpaceEvents.at(i * SpaceEvents.Cycle + 1)
		if ev.Kind == "Tormenta" and not storm then
			storm = { T = i * SpaceEvents.Cycle + 1, Place = ev.PlaceId }
		elseif ev.Kind == "Incursion" and not raid then
			raid = { T = i * SpaceEvents.Cycle + 1, Place = ev.PlaceId }
		end
	end
	check(storm and SpaceEvents.mineBonus(storm.T, storm.Place) and not SpaceEvents.mineBonus(storm.T + SpaceEvents.Active + 1, storm.Place) and not SpaceEvents.mineBonus(storm.T, "Nada"), "tormenta de asteroides: minar en su campo da más (solo mientras dura)")
	check(raid and SpaceEvents.killBonus(raid.T, raid.Place) and not SpaceEvents.killBonus(raid.T, "Nada"), "incursión pirata: Chispa extra en su sector")
	-- Móvil: zona de apuntar con el pulgar derecho y su sensibilidad
	local AimDrag = L.load("src/client/UI/AimDrag")
	local vp = Vector2.new(932, 430)
	check(AimDrag.inside(Vector2.new(700, 200), vp) and not AimDrag.inside(Vector2.new(200, 200), vp) and not AimDrag.inside(Vector2.new(800, 30), vp), "zona de apuntar: la mitad derecha (no la palanca ni el radar de arriba)")
	local y1, p1 = AimDrag.toInput(Vector2.new(14, -14), 1)
	local y2 = AimDrag.toInput(Vector2.new(14, 0), 2)
	check(y1 > 0 and p1 > 0 and near(y2, y1 * 2), "arrastrar a la derecha y arriba gira y sube el morro; la sensibilidad lo multiplica")
	AimDrag.setSensitivity(9)
	check(AimDrag.Sensitivity == AimDrag.MaxSensitivity, "la sensibilidad tiene tope")
	AimDrag.setSensitivity(1)
end

---------------------------------------------------------------------
-- Ayudante: una sesión de nave de mentira para Services/ShipSystems (reloj controlado)
---------------------------------------------------------------------
local ShipSystems = L.load("src/server/Services/ShipSystems")
local Hyperspeed = L.load("src/shared/AirCombat/Hyperspeed")
local QuantumJump = L.load("src/shared/Cosmos/QuantumJump")
local ShipWeapons = L.load("src/shared/AirCombat/ShipWeapons")
local PlanetBodies = L.load("src/shared/Cosmos/PlanetBodies")
local Layers = L.load("src/shared/Cosmos/Layers")

local clock = 100
local function fakeRoot(cf: any): any
	return setmetatable({ CFrame = cf, Parent = true }, {
		__index = function(t, k)
			if k == "Position" then
				return rawget(t, "CFrame").Position
			end
			return nil
		end,
	})
end
-- Un sitio despejado del espacio (lejos de estaciones, campos, sectores y planetas)
local OPEN = CFrame.new(-3000, 7600, -1500)
local function session(cf: any?): (any, any, { any })
	local s = { World = "Cosmos", Down = false, Root = fakeRoot(cf or OPEN), Gun = ShipWeapons.newGun(), Player = { UserId = 1 } }
	ShipSystems.attach(s)
	local sent = {}
	local enemies = {}
	local others = {}
	local ctx = {
		send = function(kind, payload)
			table.insert(sent, { Kind = kind, P = payload })
		end,
		toast = function() end,
		geo = Zone,
		now = function()
			return clock
		end,
		enemies = function()
			return enemies
		end,
		others = function()
			return others
		end,
		relocated = nil,
		relocate = function(newCf)
			s.Root.CFrame = newCf
			s.Relocated = newCf
			return true
		end,
		nav = function()
			return { Found = s.Found or {}, Missions = s.Missions or {}, PlanetStatus = function(id)
				return if id == "Tefra" then "Ready" else "Soon"
			end }
		end,
		Enemies = enemies,
		Others = others,
	}
	return s, ctx, sent
end
local function last(sent: { any }, kind: string): any
	for i = #sent, 1, -1 do
		if sent[i].Kind == kind then
			return sent[i].P
		end
	end
	return nil
end
local function tick(s: any, ctx: any, seconds: number)
	local dt = 1 / 30
	for _ = 1, math.floor(seconds / dt + 0.5) do
		clock += dt
		ShipSystems.tick(s, ctx, clock, dt)
	end
end
check(Zone.collide(OPEN.Position, 60) == nil and Zone.sectorAt(OPEN.Position) == nil and not Stations.safeAt(OPEN.Position), "(sitio de pruebas despejado en el espacio)")

---------------------------------------------------------------------
print("\n💨 Fase 4 · Impulso, freno, esquiva y energía (servidor)")
---------------------------------------------------------------------
do
	local s, ctx, sent = session()
	check(s.Abil.Energy == ShipAbilities.Energy.Max, "la nave empieza con la energía llena (del servidor)")
	ShipSystems.request(s, ctx, "Dodge", "L")
	local r = last(sent, "Ability")
	check(r and r.Ok and r.Dir == "L", "esquiva a la izquierda aprobada por el servidor")
	check(near(s.Abil.Energy, ShipAbilities.Energy.Max - ShipAbilities.Dodge.Cost), ("gasta su energía (%d)"):format(ShipAbilities.Dodge.Cost))
	check(ShipSystems.invulnerable(s, clock) and not ShipSystems.invulnerable(s, clock + ShipAbilities.Dodge.IFrames + 0.01), ("invulnerable solo %.2f s"):format(ShipAbilities.Dodge.IFrames))
	check(ShipSystems.allowance(s, clock) > 200 and ShipSystems.allowance(s, clock + 2) == 0, "margen de movimiento solo mientras dura la esquiva")
	clock += 0.2
	local e0 = s.Abil.Energy
	ShipSystems.request(s, ctx, "Dodge", "R")
	r = last(sent, "Ability")
	check(r and not r.Ok and r.Reason == "Recarga" and near(s.Abil.Energy, e0), "otra enseguida: «Aún recargando» y no gasta nada")
	clock += ShipAbilities.Dodge.Cooldown
	s.Abil.Energy = 5
	ShipSystems.request(s, ctx, "Dodge", "U")
	r = last(sent, "Ability")
	check(r and not r.Ok and r.Reason == "Energia" and s.Abil.Energy == 5, "sin energía: «Sin energía suficiente» y nada gastado")
	ShipSystems.request(s, ctx, "Dodge", "nada")
	check(s.Abil.Energy == 5, "una dirección rara no hace nada")
	-- La energía se recarga sola tras un momento sin gastar
	s.Abil.SpentAt = clock
	tick(s, ctx, 0.5)
	local still = s.Abil.Energy
	tick(s, ctx, 4)
	check(still < 6 and s.Abil.Energy > 20, ("se recarga sola tras %.1f s sin gastar (%.0f)"):format(ShipAbilities.Energy.Delay, s.Abil.Energy))
	-- Recargar (R): cañones fríos y un misil repuesto, con su recarga
	s.Gun.Heat, s.Gun.Overheated, s.Gun.Missiles = 1, true, 2
	ShipSystems.request(s, ctx, "Reload")
	check(s.Gun.Heat == 0 and not s.Gun.Overheated and s.Gun.Missiles == 3, "R: enfría los cañones y repone un misil")
	clock += 0.2
	ShipSystems.request(s, ctx, "Reload")
	check(s.Gun.Missiles == 3 and not last(sent, "Ability").Ok, "y tiene recarga (no se puede abusar)")
	clock += 0.2
	ShipSystems.request(s, ctx, "Weapon", "Laser")
	check(s.Weapon == "Laser" and ShipWeapons.spec("Laser").Damage > ShipWeapons.spec("Cannons").Damage, "el servidor sabe qué arma llevas (láser: más daño)")
end
do
	-- La esquiva aparta la nave de verdad: un disparo que iba a su sitio falla
	local s = ShipFlight.new("Caza", OPEN, "Space")
	local bolt = { Pos = OPEN.Position + Vector3.new(0, 0, -200), Dir = Vector3.new(0, 0, 1), Speed = ShipWeapons.EnemyBolt.Speed }
	local function hitsAfter(dodge: boolean): boolean
		local ship = ShipFlight.new("Caza", OPEN, "Space")
		ship.Speed = 0
		ship.Throttle = 0
		if dodge then
			ShipFlight.dodge(ship, ShipFlight.dodgeDir(ship, "R"), ShipAbilities.Dodge.Distance, ShipAbilities.Dodge.Duration)
		end
		local b = table.clone(bolt)
		local dt = 1 / 30
		for _ = 1, 30 do
			ShipFlight.advance(ship, input({ EBrake = true }), dt, SPACE)
			local from = b.Pos
			b.Pos += b.Dir * b.Speed * dt
			if ShipWeapons.segmentHits(from, b.Pos, ship.Pos, spec.Radius * 0.9 + ShipWeapons.EnemyBolt.HitRadius) then
				return true
			end
		end
		return false
	end
	check(hitsAfter(false) and not hitsAfter(true), "un disparo que iba a la nave falla si esquiva (se aparta de verdad)")
	local d = ShipFlight.new("Caza", OPEN, "Space")
	d.Speed, d.Throttle = 0, 0
	ShipFlight.dodge(d, ShipFlight.dodgeDir(d, "U"), ShipAbilities.Dodge.Distance, ShipAbilities.Dodge.Duration)
	check(ShipFlight.dodging(d), "esquivando…")
	run(d, input({ EBrake = true }), 0.6, SPACE)
	local up = d.Pos.Y - OPEN.Position.Y
	check(up > ShipAbilities.Dodge.Distance * 0.8 and not ShipFlight.dodging(d), ("esquiva hacia arriba: %.0f studs y se acaba sola (recuperación corta)"):format(up))
	check(d.RecoverUntil > 0, "con recuperación corta")
	check(ShipFlight.plausible(spec, OPEN.Position, OPEN.Position + Vector3.new(ShipAbilities.Dodge.Distance * 0.6, 0, 0), 1 / 20, ShipSystems.DodgeAllowance), "el margen del servidor cubre la esquiva aprobada")
	local _ = s
end

---------------------------------------------------------------------
print("\n🚀 Fase 5 · Hipervelocidad")
---------------------------------------------------------------------
do
	-- Recorre mucho más que el impulso
	local h = ShipFlight.new("Caza", OPEN, "Space")
	h.Override = Hyperspeed.override("Travel", spec.MaxSpeed)
	local b = ShipFlight.new("Caza", OPEN, "Space")
	run(h, input({ SetThrottle = 1 }), 3, SPACE)
	run(b, input({ SetThrottle = 1, Boost = true }), 3, SPACE)
	local dh, db = (h.Pos - OPEN.Position).Magnitude, (b.Pos - OPEN.Position).Magnitude
	check(dh > db * 3, ("en 3 s la hipervelocidad recorre %.0f studs y el impulso %.0f"):format(dh, db))
	check(near(h.Speed, Hyperspeed.Speed, 5), "llega poco a poco a su velocidad (1500)")
	-- Comprobaciones (puras)
	local base = { World = "Cosmos", Mode = "Space", Energy = 100, MinEnergy = 30, Cooldown = 0 }
	local function with(t: { [string]: any }): any
		local c = table.clone(base)
		for k, v in t do
			c[k] = v
		end
		return c
	end
	check(Hyperspeed.check(base), "en espacio abierto, con energía: se puede")
	check(select(2, Hyperspeed.check(with({ NearStation = true }))) == "Estacion", "cerca de una estación: bloqueada (y dice por qué)")
	check(select(2, Hyperspeed.check(with({ InCombat = true }))) == "Combate", "en combate: bloqueada")
	check(select(2, Hyperspeed.check(with({ Traffic = true }))) == "Trafico", "con tráfico cerca: bloqueada")
	check(select(2, Hyperspeed.check(with({ InAtmosphere = true }))) == "Atmosfera" and select(2, Hyperspeed.check(with({ Mode = "Atmos" }))) == "Atmosfera", "dentro de una atmósfera: bloqueada")
	check(select(2, Hyperspeed.check(with({ World = "Planet" }))) == "Atmosfera" and select(2, Hyperspeed.check(with({ World = "Arena" }))) == "Mundo", "en la superficie de un planeta o en la arena: no")
	check(select(2, Hyperspeed.check(with({ Energy = 10 }))) == "Energia" and select(2, Hyperspeed.check(with({ Obstacle = "un asteroide" }))) == "Obstaculo", "sin energía u obstáculo delante: no")
	-- Barrido por delante: ve el asteroide con tiempo
	local rock = Zone.rocks()[1]
	local from = rock.Center + Vector3.new(0, 0, rock.Radius + 2500)
	local hit, dist = Hyperspeed.sweep(from, Vector3.new(0, 0, -1), Hyperspeed.stopDistance(), 30, Zone.collide)
	check(hit == "un asteroide" and dist and dist < 2600, ("mira por delante y ve el asteroide a %.0f studs"):format(dist or -1))
end
do
	-- Servidor: las cuatro fases, energía y recarga
	local s, ctx, sent = session()
	ShipSystems.request(s, ctx, "Hyper")
	check(s.Hyper and s.Hyper.Phase == "Prepare" and s.Abil.Energy == 100, "1) preparación: aprobada y sin gastar nada aún")
	tick(s, ctx, Hyperspeed.Times.Prepare + 0.05)
	check(s.Hyper and s.Hyper.Phase == "Activate" and near(s.Abil.Energy, 100 - ShipAbilities.Hyper.Cost, 0.5), "2) activación: gasta al empezar")
	check(ShipSystems.allowance(s, clock) >= Hyperspeed.Speed, "el servidor admite su velocidad mientras dura")
	tick(s, ctx, Hyperspeed.Times.Activate + 0.05)
	check(s.Hyper and s.Hyper.Phase == "Travel", "3) viaje")
	local e = s.Abil.Energy
	tick(s, ctx, 2)
	check(s.Abil.Energy < e - ShipAbilities.Hyper.Drain * 1.5, ("gasta energía mientras viaja (%.0f → %.0f)"):format(e, s.Abil.Energy))
	ShipSystems.request(s, ctx, "HyperStop")
	check(s.Hyper and s.Hyper.Phase == "Decel", "se puede cortar: 4) desaceleración")
	tick(s, ctx, Hyperspeed.Times.Decel + 0.05)
	check(s.Hyper == nil and last(sent, "Hyper").Phase == "Off" and ShipAbilities.cooldownLeft(s.Abil, "Hyper", clock) > 0, "termina y empieza su recarga")
	check(ShipSystems.allowance(s, clock) > 0 and ShipSystems.allowance(s, clock + ShipSystems.Grace + 0.1) == 0, "con un margen corto por la red, que se acaba")
	ShipSystems.request(s, ctx, "Hyper")
	check(s.Hyper == nil and last(sent, "Hyper").Reason == "Recarga", "en recarga no se puede (con el motivo)")
	-- Sin energía en pleno viaje: sale sola
	local s2, ctx2, sent2 = session()
	ShipSystems.request(s2, ctx2, "Hyper")
	tick(s2, ctx2, Hyperspeed.Times.Prepare + Hyperspeed.Times.Activate + 0.1)
	s2.Abil.Energy = 1
	tick(s2, ctx2, 0.3)
	check(s2.Hyper and s2.Hyper.Phase == "Decel" and last(sent2, "Hyper").Reason == "Energia", "sin energía en el viaje: sale sola (desacelera)")
	-- Te dan en pleno viaje: sale
	local s3, ctx3 = session()
	ShipSystems.request(s3, ctx3, "Hyper")
	tick(s3, ctx3, Hyperspeed.Times.Prepare + Hyperspeed.Times.Activate + 0.1)
	ShipSystems.hurt(s3, clock)
	tick(s3, ctx3, 0.1)
	check(s3.Hyper and s3.Hyper.Phase == "Decel", "si te atacan en pleno viaje, sale")
	-- Bloqueos de verdad (servidor)
	local near1, nctx, nsent = session(Stations.launch(Stations.List[1]))
	ShipSystems.request(near1, nctx, "Hyper")
	check(near1.Hyper == nil and last(nsent, "Hyper").Reason == "Estacion", "junto a una estación: el servidor la bloquea")
	local fight, fctx, fsent = session()
	table.insert(fctx.Enemies, OPEN.Position + Vector3.new(300, 0, 0))
	ShipSystems.request(fight, fctx, "Hyper")
	check(fight.Hyper == nil and last(fsent, "Hyper").Reason == "Combate", "con enemigos cerca: bloqueada (combate)")
	local traffic, tctx, tsent = session()
	table.insert(tctx.Others, OPEN.Position + Vector3.new(80, 0, 0))
	ShipSystems.request(traffic, tctx, "Hyper")
	check(traffic.Hyper == nil and last(tsent, "Hyper").Reason == "Trafico", "con otra nave al lado: bloqueada (tráfico)")
	local body = PlanetBodies.List[1]
	local atm, actx, asent = session(CFrame.new(body.Center + Vector3.new(0, PlanetBodies.entryRadius(body) + 150, 0)))
	ShipSystems.request(atm, actx, "Hyper")
	check(atm.Hyper == nil and last(asent, "Hyper").Reason == "Atmosfera", "junto a la atmósfera de un planeta: bloqueada")
	local rock = Zone.rocks()[1]
	local toward = CFrame.new(rock.Center + Vector3.new(0, 0, rock.Radius + 1500))
	local obs, octx, osent = session(toward)
	ShipSystems.request(obs, octx, "Hyper")
	local why = last(osent, "Hyper").Reason
	check(obs.Hyper == nil and (why == "Obstaculo" or why == "Combate"), ("mirando a un asteroide cercano: bloqueada (%s)"):format(tostring(why)))
end
do
	-- Nunca atraviesa: volando hacia un asteroide en hipervelocidad, con el barrido por delante (como el
	-- cliente), sale con tiempo y no choca
	local rock = Zone.rocks()[1]
	local start = CFrame.new(rock.Center + Vector3.new(0, 0, rock.Radius + 5200))
	local sim = ShipFlight.new("Caza", start, "Space")
	sim.Speed = Hyperspeed.Speed
	sim.Override = Hyperspeed.override("Travel", spec.MaxSpeed)
	local decel = false
	local crashed = false
	local dt = 1 / 30
	for _ = 1, math.floor((Hyperspeed.Times.Decel + 3) / dt) do
		if not decel then
			local hit = Hyperspeed.sweep(sim.Pos, sim.Rot.LookVector, Hyperspeed.stopDistance(), 30, Zone.collide)
			if hit then
				decel = true
				sim.Override = Hyperspeed.override("Decel", spec.MaxSpeed)
			end
		end
		for _, e in ShipFlight.advance(sim, input({ SetThrottle = 0, EBrake = decel }), dt, COSMOS) do
			if e == "Crash" then
				crashed = true
			end
		end
		if decel and sim.Speed <= spec.MaxSpeed + 1 then
			sim.Override = nil
		end
	end
	check(decel and not crashed and Zone.collide(sim.Pos, spec.Radius) == nil, ("con el barrido por delante sale a tiempo y no atraviesa el asteroide (queda a %.0f studs)"):format((sim.Pos - rock.Center).Magnitude - rock.Radius))
	-- Y el servidor no acepta un «Pose» que cruza un asteroide aunque la velocidad sea posible
	L.services.Players = { PlayerRemoving = { Connect = function() end } }
	local AC = L.load("src/server/Services/AirCombatService")
	local fake = { Player = { UserId = 5, Name = "p" }, Root = fakeRoot(CFrame.new(rock.Center + Vector3.new(0, 0, rock.Radius + 60))), Down = false, Geo = Zone, World = "Cosmos", LastPos = rock.Center + Vector3.new(0, 0, rock.Radius + 60), LastGood = CFrame.new(rock.Center + Vector3.new(0, 0, rock.Radius + 60)), PoseAt = os.clock() - 0.1, Enemies = {}, Gun = ShipWeapons.newGun() }
	ShipSystems.attach(fake)
	fake.Hyper = { Phase = "Travel", Since = os.clock() }
	local beyond = rock.Center - Vector3.new(0, 0, rock.Radius + 60)
	pcall(AC._pose, fake, CFrame.new(beyond))
	check((fake.Root.Position - beyond).Magnitude > 10 and (fake.Rejects or 0) >= 1, "el servidor rechaza un salto que atraviesa un asteroide (vuelve al último sitio bueno)")
end

---------------------------------------------------------------------
print("\n🌀 Fase 6 · Salto cuántico")
---------------------------------------------------------------------
do
	local list = QuantumJump.list({ Found = { Campo_Hierro = 1 }, Missions = { CargaCenit = { P = 0, At = 0 } }, PlanetStatus = function(id)
		return if id == "Tefra" then "Ready" else "Soon"
	end })
	local byKind = {}
	for _, d in list do
		byKind[d.Kind] = (byKind[d.Kind] or 0) + 1
	end
	check(byKind.Estacion == 2 and byKind.Planeta == 7 and byKind.Baliza == 1 and byKind.Mision == 1 and (byKind.Campo or 0) == 3 and (byKind.Sector or 0) == 3, "destinos del registro de verdad: 2 estaciones, 7 órbitas, la baliza, la misión y los puntos de interés")
	local hierro, brasa = QuantumJump.find(list, "Campo_Hierro"), QuantumJump.find(list, "Campo_Brasa")
	check(hierro and not hierro.Locked and brasa and brasa.Locked ~= nil, "los puntos de interés solo cuando ya los has descubierto")
	local lontana, ocrea = QuantumJump.find(list, "Planeta_Tefra"), QuantumJump.find(list, "Planeta_Siroco")
	check(lontana.Note == "Se puede bajar" and ocrea.Note == "Solo órbita", "los planetas sin episodio: solo órbita")
	for _, d in list do
		if d.Kind == "Planeta" then
			local b = PlanetBodies.ById[string.sub(d.Id, 9)]
			if (d.Pos - b.Center).Magnitude <= PlanetBodies.entryRadius(b) then
				check(false, "la órbita de " .. d.Name .. " queda dentro de su atmósfera")
			end
		end
	end
	-- Validación
	local st = { World = "Cosmos", Energy = 100, Cooldown = 0, Pos = OPEN.Position }
	local alba = QuantumJump.find(list, "Estacion_Alba")
	local ok, why, cost, dist = QuantumJump.validate(st, alba)
	check(ok and cost > 0 and dist > QuantumJump.MinRange, ("a la Estación Alba: se puede (%s, ⚡ %d)"):format(NavInfo.distanceText(dist), cost))
	local function reason(t: { [string]: any }, dest: any): string?
		local c = table.clone(st)
		for k, v in t do
			c[k] = v
		end
		return select(2, QuantumJump.validate(c, dest))
	end
	check(reason({}, brasa) == "Bloqueada", "sin descubrir: no")
	check(reason({ InCombat = true }, alba) == "Combate" and reason({ World = "Planet" }, alba) == "Atmosfera" and reason({ World = "Arena" }, alba) == "Mundo", "en combate, en un planeta o en la arena: no")
	check(reason({ Energy = 5 }, alba) == "Energia" and reason({ Cooldown = 4 }, alba) == "Recarga" and reason({ Down = true }, alba) == "Derribado" and reason({ Busy = true }, alba) == "Ocupada", "sin energía, en recarga, derribado u ocupado: no")
	check(reason({ Pos = alba.Pos + Vector3.new(200, 0, 0) }, alba) == "Cerca", "demasiado cerca: «ve volando»")
	check(reason({ Pos = alba.Pos + Vector3.new(90000, 0, 0) }, alba) == "Alcance", "más allá del alcance máximo: no")
	check(select(2, QuantumJump.validate(st, nil)) == "Desconocido", "un destino que no existe: no")
	-- Llegada segura: si el sitio exacto está ocupado, busca uno libre cerca
	local rock = Zone.rocks()[1]
	local blocked = { Id = "x", Name = "x", Kind = "Baliza", Pos = rock.Center }
	local cf = QuantumJump.safeArrival(blocked, Zone.collide)
	check(cf and Zone.collide(cf.Position, QuantumJump.Clearance) == nil and (cf.Position - rock.Center).Magnitude < 600, "llegada segura: si el destino está dentro de un asteroide, sale al lado, sin tocar nada")
	for _, d in list do
		local arrival = QuantumJump.safeArrival(d, Zone.collide, function(p)
			return Zone.contains(p, 0)
		end)
		if not arrival then
			check(false, "sin sitio seguro para " .. d.Name)
		end
	end
	check(true, "todos los destinos tienen un sitio seguro para salir")
end
do
	-- Servidor: carga, salto real, sin gastar si falla, uno a la vez y se puede reintentar
	local s, ctx, sent = session()
	s.Found = { Campo_Hierro = 1 }
	ShipSystems.request(s, ctx, "QuantumList")
	local listMsg = last(sent, "Quantum")
	check(listMsg and listMsg.Phase == "List" and #listMsg.List >= 13, "el selector recibe la lista del servidor (con distancia, coste y motivo)")
	clock += 0.2
	ShipSystems.request(s, ctx, "Quantum", "Estacion_Cenit")
	local charge = last(sent, "Quantum")
	check(charge.Phase == "Charge" and s.Quantum and s.Abil.Energy == 100, "carga el salto (aún sin gastar)")
	clock += 0.2
	ShipSystems.request(s, ctx, "Quantum", "Estacion_Alba")
	check(last(sent, "Quantum").Reason == "Ocupada" and s.Quantum.Id == "Estacion_Cenit", "no hay doble salto: el segundo se rechaza")
	tick(s, ctx, 1)
	check(s.Relocated == nil, "a mitad de carga la nave sigue donde estaba")
	tick(s, ctx, ShipAbilities.Quantum.Charge)
	local done = last(sent, "Quantum")
	local cenit = Stations.ById.Cenit
	check(done.Phase == "Done" and s.Relocated and (s.Relocated.Position - Stations.launch(cenit).Position).Magnitude < 500, "salta de verdad: el servidor mueve la nave junto a la Estación Cénit")
	check(Zone.collide(s.Relocated.Position, QuantumJump.Clearance) == nil, "y sale en un sitio libre (sin tocar nada)")
	check(s.Abil.Energy < 100 and near(s.Abil.Energy, 100 - charge.Cost, 0.5) and ShipAbilities.cooldownLeft(s.Abil, "Quantum", clock) > 0, "solo entonces gasta su coste y empieza la recarga")
	-- Falla durante la carga: te dan → no gasta nada, la nave no se queda atascada, se puede reintentar
	local f, fctx, fsent = session()
	clock += 1
	ShipSystems.request(f, fctx, "Quantum", "Estacion_Alba")
	tick(f, fctx, 1)
	ShipSystems.hurt(f, clock)
	tick(f, fctx, 0.1)
	local fail = last(fsent, "Quantum")
	check(fail.Phase == "Fail" and fail.Reason == "Danado" and f.Abil.Energy == 100 and f.Quantum == nil and f.Relocated == nil, "si te dan durante la carga: falla, dice por qué y no gasta nada")
	clock += 7
	ShipSystems.request(f, fctx, "Quantum", "Estacion_Alba")
	tick(f, fctx, ShipAbilities.Quantum.Charge + 0.1)
	check(last(fsent, "Quantum").Phase == "Done" and f.Relocated ~= nil, "se puede reintentar y salta")
	-- Cancelar
	local c, cctx, csent = session()
	clock += 1
	ShipSystems.request(c, cctx, "Quantum", "Baliza")
	ShipSystems.request(c, cctx, "QuantumCancel")
	check(last(csent, "Quantum").Reason == "Cancelado" and c.Quantum == nil and c.Abil.Energy == 100, "cancelar: sin gastar nada")
	-- Destinos prohibidos
	local p, pctx, psent = session()
	clock += 1
	ShipSystems.request(p, pctx, "Quantum", "Campo_Brasa")
	check(last(psent, "Quantum").Reason == "Bloqueada" and p.Quantum == nil, "un punto sin descubrir: rechazado")
	clock += 1
	ShipSystems.request(p, pctx, "Quantum", "NoExiste")
	check(last(psent, "Quantum").Reason == "Desconocido", "un destino inventado: rechazado")
	clock += 1
	p.World = "Planet"
	ShipSystems.request(p, pctx, "Quantum", "Baliza")
	check(last(psent, "Quantum").Reason == "Atmosfera" and p.Abil.Energy == 100, "desde la superficie de un planeta: rechazado sin gastar")
	-- (y si el movimiento final no se puede hacer, devuelve la energía)
	local r, rctx, rsent = session()
	rctx.relocate = function()
		return false
	end
	clock += 1
	ShipSystems.request(r, rctx, "Quantum", "Baliza")
	tick(r, rctx, ShipAbilities.Quantum.Charge + 0.1)
	check(last(rsent, "Quantum").Phase == "Fail" and near(r.Abil.Energy, 100, 0.5), "si el servidor no puede mover la nave, no se pierde energía")
	-- Descubrir volando (SpaceService → data.Space.Found)
	local found = {}
	local newOnes = NavInfo.discoverAt(Zone.Fields[2].Center, found)
	check(#newOnes >= 1 and newOnes[1].Id ~= nil, "al entrar volando en un campo o sector, se descubre")
	local _ = Layers
end

---------------------------------------------------------------------
print("\n⚔️ Fase 7 · Combate: fijado, objetivos, misiles enemigos y amenazas")
---------------------------------------------------------------------
local ShipCombat = L.load("src/shared/AirCombat/ShipCombat")
local Lock = L.load("src/shared/AirCombat/Lock")
local EnemyAI = L.load("src/shared/AirCombat/EnemyAI")
local Shields = L.load("src/shared/AirCombat/Shields")
local ACS = L.load("src/server/Services/AirCombatService")
do
	local o = OPEN.Position
	local fwd = Vector3.new(0, 0, -1)
	check(ShipCombat.canLock(o, fwd, o + Vector3.new(0, 0, -600)), "fijar un misil: delante y a tiro, sí")
	check(select(2, ShipCombat.canLock(o, fwd, o + Vector3.new(0, 0, -2000))) == "Lejos", "demasiado lejos: no («Lejos»)")
	check(select(2, ShipCombat.canLock(o, fwd, o + Vector3.new(600, 0, 0))) == "Angulo", "fuera del cono: no («Angulo»)")
	local rock = Zone.rocks()[1]
	local from = rock.Center + Vector3.new(0, 0, rock.Radius + 300)
	local behind = rock.Center - Vector3.new(0, 0, rock.Radius + 200)
	check(select(2, ShipCombat.canLock(from, fwd, behind, 2000, nil, Zone.segmentBlocked)) == "Tapado", "con un asteroide en medio: no («Tapado», línea de visión)")
	-- Cambiar de objetivo: el siguiente por ángulo, y vuelta a empezar
	local list = { { Id = "a", Pos = o + Vector3.new(0, 0, -500) }, { Id = "b", Pos = o + Vector3.new(150, 0, -500) }, { Id = "c", Pos = o + Vector3.new(-450, 0, -500) }, { Id = "lejos", Pos = o + Vector3.new(0, 0, -9000) } }
	local first = ShipCombat.cycle(list, nil, o, fwd, 1400)
	local second = ShipCombat.cycle(list, first, o, fwd, 1400)
	local third = ShipCombat.cycle(list, second, o, fwd, 1400)
	check(first == "a" and second == "b" and third == "c" and ShipCombat.cycle(list, third, o, fwd, 1400) == "a", "Tab / cruceta / OBJETIVO: a → b → c → a (por ángulo; los lejanos no)")
	-- La fijación respeta el elegido a mano y la línea de visión
	local L1 = Lock.new()
	Lock.update(L1, o, fwd, list, 0.1)
	check(L1.Target == "a", "sin elegir, fija el más centrado")
	Lock.update(L1, o, fwd, list, 0.1, nil, "b")
	check(L1.Target == "b" and L1.Progress == 0, "elegido a mano «b»: cambia y empieza de cero")
	local L2 = Lock.new()
	local hidden = { { Id = "x", Pos = behind } }
	Lock.update(L2, from, fwd, hidden, 0.1, nil, nil, Zone.segmentBlocked)
	Lock.update(L2, from, fwd, hidden, 2, nil, nil, Zone.segmentBlocked)
	check(not L2.Locked, "detrás de un asteroide no llega a fijarse")
	-- Amenaza: el misil más cercano y su dirección
	local dir, dist = ShipCombat.incoming(o, { { Pos = o + Vector3.new(300, 0, 0) }, { Pos = o + Vector3.new(0, 0, 900) } })
	check(dir and dir.X > 0.99 and near(dist or 0, 300), "aviso de misil: el más cercano, con su dirección (derecha) y distancia")
end
do
	-- Misiles enemigos: buscan la nave y dañan; las bengalas los engañan; la esquiva los hace fallar
	local function shipSession(): any
		local s = { Player = { UserId = 9, Name = "p", Parent = true }, Root = fakeRoot(OPEN), Down = false, Geo = Zone, World = "Cosmos", Hull = Shields.new("Caza"), Gun = ShipWeapons.newGun(), Enemies = {}, EnemyMissiles = {}, Bolts = {}, Missiles = {} }
		ShipSystems.attach(s)
		return s
	end
	local function launch(s: any, from: Vector3)
		table.insert(s.EnemyMissiles, { Id = "em" .. #s.EnemyMissiles, Pos = from, Dir = (OPEN.Position - from).Unit, Speed = 120, Life = ShipCombat.EnemyMissile.Life })
	end
	local function run(s: any, seconds: number)
		local dt = 1 / 30
		for _ = 1, math.floor(seconds / dt) do
			clock += dt
			ACS._stepEnemyMissiles(s, dt, clock)
		end
	end
	local s = shipSession()
	launch(s, OPEN.Position + Vector3.new(0, 0, -500))
	local before = s.Hull.Shield + s.Hull.Hull
	run(s, 4)
	check(#s.EnemyMissiles == 0 and s.Hull.Shield + s.Hull.Hull < before - 10, ("el misil de un caza busca tu nave y te da (%.0f de daño)"):format(before - s.Hull.Shield - s.Hull.Hull))
	local f = shipSession()
	launch(f, OPEN.Position + Vector3.new(0, 0, -500))
	run(f, 0.3)
	local ctx = { send = function() end, fx = nil }
	check(ShipSystems.flares(f, ctx, clock) and f.Flares.Charges == f.Flares.Max - 1, "bengalas: gasta una carga")
	check(not ShipSystems.flares(f, ctx, clock + 0.1), "recarga corta: otra enseguida no")
	local hp = f.Hull.Shield + f.Hull.Hull
	run(f, 4)
	check(#f.EnemyMissiles == 0 and f.Hull.Shield + f.Hull.Hull == hp, "y el misil se va al señuelo: no te da")
	f.Flares.Charges = 0
	check(select(2, ShipCombat.flare(f.Flares, clock + 10)) == "SinCargas", "sin cargas: no (y se reponen solas)")
	ShipCombat.flareTick(f.Flares, clock + 10)
	ShipCombat.flareTick(f.Flares, clock + 10 + ShipCombat.Flares.Regen + 0.1)
	check(f.Flares.Charges >= 1, "una carga vuelve sola con el tiempo")
	-- Esquivar: invulnerable un instante y la nave se aparta
	local d = shipSession()
	launch(d, OPEN.Position + Vector3.new(0, 0, -60))
	d.IFramesUntil = os.clock() + 5 -- (el servidor mira su propio reloj)
	local hp2 = d.Hull.Shield + d.Hull.Hull
	run(d, 1)
	check(d.Hull.Shield + d.Hull.Hull == hp2, "durante la invulnerabilidad de la esquiva el misil no hace daño")
	-- Un caza de verdad (servidor) lanza misiles con las mismas reglas
	L.services.Players = { PlayerRemoving = { Connect = function() end } }
	local AirArena = L.load("src/server/World/AirArena")
	local folder = roblox.Instance.new("Model")
	local player = { UserId = 31, Name = "q", Parent = true, SetAttribute = function() end }
	local ship = AirArena.ship(OPEN)
	ship.Parent = roblox.Instance.new("Folder")
	local cs: any = {
		Player = player, Ship = ship, Root = fakeRoot(OPEN), Seat = ship:FindFirstChild("ShipSeat"), Humanoid = { Parent = true, Health = 100 },
		Section = "Space", Difficulty = "Normal", Hull = Shields.new("Caza"), Gun = ShipWeapons.newGun(), Spawner = L.load("src/shared/AirCombat/Waves").new({ Section = "Space" }),
		Enemies = {}, Folder = folder, Bolts = {}, Missiles = {}, EnemyMissiles = {}, LastPos = OPEN.Position, LastGood = OPEN, LastAt = 0, Down = false, DownUntil = 0,
		Score = 0, Kills = 0, NextId = 0, StateAt = 0, Exiting = false, Conns = {}, Geo = Zone, World = "Cosmos", Free = true,
	}
	ShipSystems.attach(cs)
	ACS._sessions[player] = cs
	local id = ACS.spawnEnemy(player, "Caza", OPEN.Position + Vector3.new(0, 0, -500))
	local rec = id and cs.Enemies[id]
	check(rec ~= nil and rec.Model:GetAttribute("Level") ~= nil and rec.Model:GetAttribute("Hp") == rec.Model:GetAttribute("MaxHp"), "el enemigo lleva su nivel y su salud para el HUD del objetivo")
	if rec then
		rec.AI.Look = Vector3.new(0, 0, 1)
		rec.AI.Mult.Speed = 0
		rec.AI.NextMissile = 0
		rec.AI.NextFire = math.huge
		for _ = 1, 6 do
			pcall(ACS._step, cs, 1 / 30)
			rec.AI.Pos = OPEN.Position + Vector3.new(0, 0, -500)
			rec.AI.Look = Vector3.new(0, 0, 1)
		end
		check(#cs.EnemyMissiles >= 1 or (cs.Hull.Shield + cs.Hull.Hull) < 160, "un caza enemigo que te tiene a tiro te lanza un misil")
		-- Al dañarlo, su salud baja en el HUD
		local hp0 = rec.Model:GetAttribute("Hp")
		for _ = 1, 40 do
			cs.Gun.NextLaser, cs.Gun.Heat, cs.Gun.Overheated = 0, 0, false
			cs.Root.CFrame = OPEN
			ACS._fire(cs, Vector3.new(0, 0, -1))
			pcall(ACS._step, cs, 1 / 30)
			rec.AI.Pos = OPEN.Position + Vector3.new(0, 0, -500)
			if not cs.Enemies[id] then
				break
			end
		end
		check(cs.Enemies[id] == nil or (rec.Model:GetAttribute("Hp") or hp0) < hp0, "la salud del objetivo baja al darle")
	end
	ACS._sessions[player] = nil
end

---------------------------------------------------------------------
print("\n🛡️ Fase 8 · Camuflaje, sobrecarga del escudo, modos y drones")
---------------------------------------------------------------------
do
	local s, ctx, sent = session()
	s.Hull = Shields.new("Caza")
	-- Sobrecarga
	ShipSystems.request(s, ctx, "Overload")
	check(s.Overload and s.Hull.Shield > s.Hull.MaxShield * 1.5 and near(s.Abil.Energy, 100 - ShipCombat.Overload.Cost, 0.5), "sobrecarga: +60 % de escudo y gasta energía")
	tick(s, ctx, ShipCombat.Overload.Seconds + 0.1)
	check(s.Overload == nil and s.Hull.Shield <= s.Hull.MaxShield, "al acabar vuelve a su máximo")
	s.Hull.Shield = 10
	check(Shields.regen(s.Hull, clock + 1, 1) == 0, "y se recalienta: un rato sin regenerar")
	check(Shields.regen(s.Hull, clock + ShipCombat.Overload.Overheat + 0.5, 1) > 0, "luego vuelve a regenerar")
	clock += 0.2
	ShipSystems.request(s, ctx, "Overload")
	check(last(sent, "Ability").Reason == "Recarga", "con recarga")
	-- Camuflaje
	clock += 0.2
	ShipSystems.request(s, ctx, "Cloak")
	check(s.Cloak ~= nil, "camuflaje activado")
	local e0 = s.Abil.Energy
	tick(s, ctx, 2)
	check(s.Abil.Energy < e0 - ShipCombat.Cloak.Drain, "gasta energía mientras dura")
	local enemy = EnemyAI.new("e", "Caza", OPEN.Position + Vector3.new(0, 0, -800))
	local pilotFar = { Id = "1", Pos = OPEN.Position, Detect = ShipCombat.Cloak.Detect }
	check(EnemyAI.pickTarget(enemy, { pilotFar }, clock) == nil, "a 800 studs un enemigo no te ve camuflado")
	local enemyNear = EnemyAI.new("e2", "Caza", OPEN.Position + Vector3.new(0, 0, -200))
	check(EnemyAI.pickTarget(enemyNear, { pilotFar }, clock) == "1", "muy cerca sí (no es invisibilidad total)")
	check(EnemyAI.pickTarget(enemy, { { Id = "1", Pos = OPEN.Position } }, clock) == "1", "sin camuflaje, te ve de lejos")
	check(ShipCombat.cloakAlpha(0, false) == 0 and ShipCombat.cloakAlpha(10, false) > ShipCombat.cloakAlpha(10, true) and ShipCombat.cloakAlpha(0.4, false) < ShipCombat.cloakAlpha(10, false), "se desvanece poco a poco (los demás casi no te ven; tú, a medias)")
	ShipSystems.cloakBreak(s, ctx, clock, "Disparo")
	check(s.Cloak == nil and ShipAbilities.cooldownLeft(s.Abil, "Cloak", clock) > 0, "disparar lo rompe y empieza su recarga")
	local c2, cctx = session()
	ShipSystems.request(c2, cctx, "Cloak")
	tick(c2, cctx, ShipCombat.Cloak.MaxSeconds + 0.2)
	check(c2.Cloak == nil, "dura como mucho unos segundos")
	-- Modos: exploración sin misiles y a media cadencia; escáner
	local m, mctx, msent = session()
	ShipSystems.request(m, mctx, "Mode", "Explore")
	check(m.FlightMode == "Explore" and not ShipCombat.weaponRules("Explore").Missiles and ShipCombat.weaponRules("Explore").Rate < 1, "modo exploración: sin misiles y armas a media cadencia")
	local discovered = {}
	mctx.discover = function(_, r)
		table.insert(discovered, r)
		return { "Campo Brasa" }
	end
	clock += 0.2
	ShipSystems.request(m, mctx, "Scan")
	check(#discovered == 1 and discovered[1] == ShipCombat.Scan.Radius and last(msent, "Scan").Found[1] == "Campo Brasa", "pulso del escáner: descubre lejos")
	clock += 0.2
	ShipSystems.request(m, mctx, "Scan")
	check(#discovered == 1, "el escáner tiene su ritmo (no se puede abusar)")
	clock += 0.2
	ShipSystems.request(m, mctx, "Mode", "Combat")
	clock += 5
	ShipSystems.request(m, mctx, "Scan")
	check(#discovered == 1, "fuera del modo exploración (y sin dron explorador) no escanea")
	check(ShipCombat.nextMode("Combat") == "Cruise" and ShipCombat.nextMode("Cruise") == "Explore" and ShipCombat.nextMode("Explore") == "Combat", "T: combate → crucero → exploración")
	local ex = ShipFlight.new("Caza", OPEN, "Space")
	ShipFlight.setMode(ex, "Explore")
	run(ex, input({ SetThrottle = 1 }), 5, SPACE)
	check(ex.Speed > spec.MaxSpeed * 1.1, "en exploración también va más deprisa")
end
do
	-- Drones: solo los desbloqueados; estado, duración, límite, destrucción y su tarea
	local s, ctx, sent = session()
	s.Hull = Shields.new("Caza")
	ShipSystems.request(s, ctx, "Drone")
	check(s.Drone == nil and last(sent, "Ability").Reason == "SinDron", "sin desbloquear ninguno no sale (y dice dónde se consigue)")
	s.Unlocked, s.DroneKind = { Reparacion = 1 }, "Reparacion"
	clock += 0.2
	ShipSystems.request(s, ctx, "Drone")
	check(s.Drone and s.Drone.Kind == "Reparacion" and s.Abil.Energy < 100, "dron de reparación en marcha (gasta energía)")
	s.Hull.Hull = 40
	tick(s, ctx, 3)
	check(s.Hull.Hull > 45, ("repara el casco (%.0f)"):format(s.Hull.Hull))
	check((s.Drone.Pos - s.Root.Position).Magnitude < ShipCombat.Drones.Reparacion.Range, "va con la nave (dentro de su límite)")
	s.Root.CFrame = CFrame.new(OPEN.Position + Vector3.new(5000, 0, 0))
	tick(s, ctx, 0.1)
	check((s.Drone.Pos - s.Root.Position).Magnitude < ShipCombat.Drones.Reparacion.Range, "si la nave salta, el dron va con ella")
	local st = ShipSystems.state(s, ctx, clock)
	check(st.Drone and st.Drone.Kind == "Reparacion" and st.Drone.Left > 0 and st.Drone.Hp > 0, "su estado sale en el HUD (vida y tiempo)")
	ShipSystems.droneHit(s, ctx, clock, 999)
	check(s.Drone == nil and last(sent, "Ability").Reason == "Destruido" and ShipAbilities.cooldownLeft(s.Abil, "Drone", clock) > 0, "lo pueden destruir (y queda en recarga)")
	-- Defensa: para un misil que viene
	local dfs, dctx = session()
	dfs.Unlocked, dfs.DroneKind = { Defensa = 1 }, "Defensa"
	ShipSystems.request(dfs, dctx, "Drone")
	tick(dfs, dctx, 0.6)
	check(ShipSystems.intercept(dfs, dfs.Root.Position + Vector3.new(0, 0, -30), clock) and not ShipSystems.intercept(dfs, dfs.Root.Position + Vector3.new(0, 0, -30), clock), "el dron de defensa para un proyectil cerca (y luego necesita un momento)")
	-- Combate: dispara a un enemigo cercano
	local cmb, kctx = session()
	cmb.Unlocked, cmb.DroneKind = { Combate = 1 }, "Combate"
	local shots = 0
	kctx.droneShot = function()
		shots += 1
	end
	table.insert(kctx.Enemies, OPEN.Position + Vector3.new(0, 0, -300))
	ShipSystems.request(cmb, kctx, "Drone")
	tick(cmb, kctx, 2)
	check(shots >= 2, ("el dron de combate dispara a los enemigos cercanos (%d disparos)"):format(shots))
	-- Exploración: escanea solo
	local exp, ectx = session()
	exp.Unlocked, exp.DroneKind = { Exploracion = 1 }, "Exploracion"
	local scans = 0
	ectx.discover = function()
		scans += 1
		return {}
	end
	ShipSystems.request(exp, ectx, "Drone")
	tick(exp, ectx, 5)
	check(scans >= 1, "el dron explorador escanea solo (descubre puntos de interés)")
	-- Se acaba solo
	tick(exp, ectx, ShipCombat.Drones.Exploracion.Seconds)
	check(exp.Drone == nil, "dura un tiempo y vuelve")
	check(ShipCombat.canDeploy({ Combate = 1 }, "Defensa", 100, 0, false) == false and ShipCombat.canDeploy({ Defensa = 1 }, "Defensa", 100, 0, false), "solo los desbloqueados")
end

---------------------------------------------------------------------
print("\n🛠️ Fase 9 · Integración: mejoras, drones en el taller y guardado")
---------------------------------------------------------------------
do
	check(ShipCombat.upgradePrice("Blindaje", 0).Money == 800 and ShipCombat.upgradePrice("Blindaje", 3) == nil, "precios del taller por nivel (con tope)")
	local b = ShipCombat.bonuses({ Blindaje = 2, Baterias = 1, Bengalas = 9 })
	check(b.Hull == 40 and b.Energy == 15 and b.Flares == 2, "lo que dan las mejoras (y no más del máximo)")
	local s = { World = "Cosmos", Down = false, Root = fakeRoot(OPEN), Gun = ShipWeapons.newGun(), Hull = Shields.new("Caza"), Upgrades = { Blindaje = 1, Baterias = 2, Bengalas = 1 } }
	ShipSystems.attach(s)
	check(s.Hull.MaxHull == 120 and s.Abil.Max == 130 and s.Flares.Max == ShipCombat.Flares.Charges + 1, "la nave sale con las mejoras (casco, energía y bengalas)")
	ShipSystems.attach(s)
	check(s.Hull.MaxHull == 120, "reaparecer no suma las mejoras dos veces")
	-- Comprar en el taller (dinero de Valmar y Chispas; nada de Robux)
	local data = { Money = 2000, Space = { Chispas = 12 } }
	L.mock("src/server/Services/DataService", {
		get = function()
			return data
		end,
		spend = function(_, price)
			if data.Money < price then
				return false
			end
			data.Money -= price
			return true
		end,
		addMoney = function()
			return true
		end,
	})
	local Space = L.load("src/server/Services/SpaceService")
	local pl = { UserId = 55, Name = "c" }
	local ok = Space.buyUpgrade(pl, "Blindaje")
	check(ok and data.Space.Upgrades.Blindaje == 1 and data.Money == 1200 and data.Space.Chispas == 8, "comprar blindaje: cuesta dinero y Chispas y se guarda en data.Space")
	local okD, whyD = Space.buyDrone(pl, "Combate")
	check(not okD and whyD == "Chispas" and data.Space.Drones.Combate == nil, "sin Chispas suficientes no se desbloquea (y no se cobra)")
	data.Space.Chispas = 20
	data.Money = 2000
	check(Space.buyDrone(pl, "Exploracion") and data.Space.Drones.Exploracion and data.Space.DroneKind == "Exploracion", "desbloquear el dron explorador y equiparlo")
	local lo = Space.loadoutFor(pl)
	check(lo.Upgrades.Blindaje == 1 and lo.Drones.Exploracion and lo.DroneKind == "Exploracion", "la nave lleva lo comprado al subir (mejoras y dron)")
	local old = { Money = 0, Space = { Chispas = 0 } }
	data = old
	local loOld = Space.loadoutFor(pl)
	check(type(loOld.Upgrades) == "table" and type(loOld.Drones) == "table" and loOld.DroneKind == nil, "partidas viejas: valores por defecto (no se pierde nada)")
	local found = Space.scanFor(pl, Zone.Fields[2].Center, 500)
	check(#found >= 1 and old.Space.Found["Campo_Brasa"] ~= nil, "el escáner descubre y lo guarda (destinos del salto)")
end

---------------------------------------------------------------------
print("\n👥 Fase 11 · Varios pilotos y rendimiento")
---------------------------------------------------------------------
do
	-- Tres pilotos en la arena: A y B cerca, C muy lejos
	local got: { [number]: { any } } = {}
	ACS._setRemote({
		FireClient = function(_, player, kind, payload)
			got[player.UserId] = got[player.UserId] or {}
			table.insert(got[player.UserId], { Kind = kind, P = payload })
		end,
	})
	local function attrShip(): any
		local attrs = {}
		return {
			Attrs = attrs,
			SetAttribute = function(_, k, v)
				attrs[k] = v
			end,
			GetAttribute = function(_, k)
				return attrs[k]
			end,
		}
	end
	local function pilot(id: number, cf: any): any
		local player = { UserId = id, Name = "p" .. id, Parent = true, SetAttribute = function() end }
		local s: any = {
			Player = player, Ship = attrShip(), Root = fakeRoot(cf), Down = false, Geo = Zone, World = "Cosmos", Free = true,
			Hull = Shields.new("Caza"), Gun = ShipWeapons.newGun(), Enemies = {}, EnemyMissiles = {}, Bolts = {}, Missiles = {},
		}
		ShipSystems.attach(s)
		ACS._sessions[player] = s
		return s
	end
	local A = pilot(101, OPEN)
	local B = pilot(102, OPEN * CFrame.new(400, 0, 0))
	local C = pilot(103, OPEN * CFrame.new(20000, 0, 0))
	local ctxA = ACS._systemsCtx(A)
	ctxA.fx("Flares", { Pos = A.Root.Position })
	local function gotFx(id: number): boolean
		for _, m in got[id] or {} do
			if m.Kind == "Fx" and m.P.Pilot == 101 then
				return true
			end
		end
		return false
	end
	check(gotFx(101) and gotFx(102) and not gotFx(103), "los efectos de una habilidad solo llegan a los pilotos cercanos (ahorra red)")
	local othersA = ctxA.others()
	check(#othersA == 2, "cada piloto sabe dónde están los demás (para no saltar encima de nadie)")
	-- Camuflaje de A: su nave lo dice a los demás (radar y transparencia) y sus enemigos no le ven de lejos
	local cA = { send = function() end, toast = function() end, geo = Zone, now = function()
		return clock
	end, enemies = function()
		return {}
	end, others = function()
		return {}
	end }
	clock += 1
	ShipSystems.request(A, cA, "Cloak")
	check(A.Cloak ~= nil and A.Ship.Attrs.Cloak ~= nil and B.Ship.Attrs.Cloak == nil, "el camuflaje de A se ve en su nave (los demás la ocultan en el radar); B sigue normal")
	local pA, pB = ACS._pilotsOf(A)[1], ACS._pilotsOf(B)[1]
	check(pA.Detect == ShipCombat.Cloak.Detect and pB.Detect == nil, "a los enemigos A les llega camuflado y B no")
	local hunter = EnemyAI.new("h", "Caza", OPEN.Position + Vector3.new(0, 0, -900))
	check(EnemyAI.pickTarget(hunter, { pA }, clock) == nil and EnemyAI.pickTarget(hunter, { pB }, clock) == tostring(B.Player.UserId), "un caza a 900 no ve a A (camuflado) pero sí a B")
	ShipSystems.cloakBreak(A, cA, clock, "Disparo")
	check(A.Ship.Attrs.Cloak == nil, "al romperse, la nave vuelve a verse")
	-- Sobrecarga visible para los demás
	clock += 1
	ShipSystems.request(B, cA, "Overload")
	check(B.Ship.Attrs.Overload == true, "la sobrecarga del escudo de B se ve en su nave")
	-- Un solo dron por piloto: pulsar otra vez lo recoge
	A.Unlocked, A.DroneKind = { Defensa = 1 }, "Defensa"
	clock += 1
	ShipSystems.request(A, cA, "Drone")
	local first = A.Drone
	clock += 1
	ShipSystems.request(A, cA, "Drone")
	check(first ~= nil and A.Drone == nil, "un solo dron a la vez (pulsar otra vez lo recoge)")
	-- Tope de misiles enemigos: aunque haya muchos cazas, no más de Max a la vez
	L.services.Players = { PlayerRemoving = { Connect = function() end } }
	local AirArena = L.load("src/server/World/AirArena")
	local ship = AirArena.ship(OPEN)
	ship.Parent = roblox.Instance.new("Folder")
	local player = { UserId = 104, Name = "m", Parent = true, SetAttribute = function() end }
	local cs: any = {
		Player = player, Ship = ship, Root = fakeRoot(OPEN), Seat = ship:FindFirstChild("ShipSeat"), Humanoid = { Parent = true, Health = 100 },
		Section = "Space", Difficulty = "Normal", Hull = Shields.new("Caza"), Gun = ShipWeapons.newGun(), Spawner = L.load("src/shared/AirCombat/Waves").new({ Section = "Space" }),
		Enemies = {}, Folder = roblox.Instance.new("Model"), Bolts = {}, Missiles = {}, EnemyMissiles = {}, LastPos = OPEN.Position, LastGood = OPEN, LastAt = 0, Down = false, DownUntil = 0,
		Score = 0, Kills = 0, NextId = 0, StateAt = 0, Exiting = false, Conns = {}, Geo = Zone, World = "Cosmos", Free = true,
	}
	ShipSystems.attach(cs)
	cs.Hull.MaxHull, cs.Hull.Hull = 1e9, 1e9
	ACS._sessions[player] = cs
	local ids = {}
	for i = 1, 10 do
		local id = ACS.spawnEnemy(player, "Caza", OPEN.Position + Vector3.new((i - 5) * 30, 0, -600))
		if id then
			table.insert(ids, id)
		end
	end
	local most = 0
	for _ = 1, 90 do
		for _, id in ids do
			local rec = cs.Enemies[id]
			if rec then
				rec.AI.Look = Vector3.new(0, 0, 1)
				rec.AI.Mult.Speed = 0
				if (rec.AI.NextMissile or 0) > 0 then
					rec.AI.NextMissile = 0
				end
				rec.AI.NextFire = math.huge
			end
		end
		pcall(ACS._step, cs, 1 / 30)
		most = math.max(most, #cs.EnemyMissiles)
	end
	check(most >= 1 and most <= ShipCombat.EnemyMissile.Max, ("tope de misiles enemigos a la vez (%d de %d)"):format(most, ShipCombat.EnemyMissile.Max))
	for p in ACS._sessions do
		ACS._sessions[p] = nil
	end
	ACS._setRemote(nil)
end

---------------------------------------------------------------------
print("\n🛸 Nave realista de malla «HX-7 Halcón» (docs/espacio-aaa/nave-realista.md)")
---------------------------------------------------------------------
do
	local serde = require("@lune/serde")
	local Instance = roblox.Instance
	local Enum = roblox.Enum
	local ShipModel = L.load("src/shared/AirCombat/ShipModel")
	local Malla = L.load("src/shared/AirCombat/NaveMalla")
	local Ids = L.load("src/shared/AirCombat/NaveAssetIds")
	local NaveLoader = L.load("src/server/World/NaveLoader")
	local ShipInfo = L.load("src/shared/AirCombat/ShipInfo")
	ShipModel.setMeshTemplate(nil)

	-- 1. Sin ids: la de piezas (el respaldo), con la misma API de siempre
	local idsOk = type(Ids.Completa) == "string" and (Ids.Completa == "" or string.match(Ids.Completa, "^rbxassetid://%d+$") ~= nil)
	for _, group in { Ids.Piezas, Ids.Texturas } do
		for _, v in group do
			idsOk = idsOk and type(v) == "string" and string.match(v, "^rbxassetid://%d+$") ~= nil
		end
	end
	check(idsOk, "NaveAssetIds: Completa, Piezas y Texturas son rbxassetid (vacío hasta scripts/upload-nave.sh)")
	local NoIds = { Completa = "", Piezas = {}, Texturas = {} }
	check(not NaveLoader.hasIds(NoIds), "sin ids subidos no hay nada que descargar")
	local none, why = NaveLoader.prepare(NoIds, function()
		error("no debería descargar nada")
	end)
	check(none == nil and string.find(why, "sin ids", 1, true) ~= nil, "sin ids no se descarga nada y no hay plantilla")
	local fb = ShipModel.build("Caza", CFrame.new(0, 100, 0))
	check(not ShipModel.meshReady() and fb:GetAttribute("NaveVisual") == "Piezas" and fb:FindFirstChild("ShipSeat") and fb:FindFirstChild("Fuselaje") and fb:FindFirstChild("Escape"), "sin malla: la nave de piezas (respaldo) con asiento, fuselaje y motores")

	-- 2. Los archivos exportados: triángulos contados en los OBJ, presupuestos y texturas
	local manifest = serde.decode("json", fs.readFile("assets/nave/manifest.json"))
	local function objTris(path: string): number
		local text = fs.readFile(path)
		local n = 0
		for line in string.gmatch(text, "[^\n]+") do
			if string.sub(line, 1, 2) == "f " then
				local verts = 0
				for _ in string.gmatch(string.sub(line, 3), "%S+") do
					verts += 1
				end
				n += math.max(verts - 2, 0)
			end
		end
		return n
	end
	local over, mismatch, missingFiles, total = {}, {}, {}, 0
	local byName = {}
	for _, p in manifest.Pieces do
		byName[p.Name] = p
		if not (fs.isFile("assets/nave/" .. p.Fbx) and fs.isFile("assets/nave/" .. p.Obj)) then
			table.insert(missingFiles, p.Name)
			continue
		end
		local tris = objTris("assets/nave/" .. p.Obj)
		if tris ~= p.Tris then
			table.insert(mismatch, ("%s %d≠%d"):format(p.Name, tris, p.Tris))
		end
		if tris > 20000 then
			table.insert(over, ("%s %d"):format(p.Name, tris))
		end
		if not p.Lod then
			total += tris
		end
	end
	check(#missingFiles == 0, "cada pieza tiene su FBX (para subir) y su OBJ" .. (if #missingFiles > 0 then ": faltan " .. table.concat(missingFiles, ", ") else ""))
	check(#mismatch == 0, "los triángulos del manifest son los de los archivos exportados" .. (if #mismatch > 0 then ": " .. table.concat(mismatch, ", ") else ""))
	check(#over == 0, ("cada MeshPart ≤ 20.000 triángulos (el límite de Roblox); la nave entera %d"):format(total) .. (if #over > 0 then ": " .. table.concat(over, ", ") else ""))
	local lod = byName.NaveLOD
	check(lod and lod.Lod and lod.Tris >= 3000 and lod.Tris <= 5000, ("versión lejana NaveLOD de 3–5 mil triángulos (%s)"):format(lod and tostring(lod.Tris) or "falta"))
	for _, name in { "Fuselaje", "CabinaFrente", "Cabina", "Alas", "Armas", "Motores", "TrenPata", "BrilloAzul", "BrilloRojo" } do
		if not byName[name] then
			check(false, "falta la pieza " .. name)
		end
	end
	local function pngSize(path: string): (number, number)
		local data = fs.readFile(path)
		return string.unpack(">I4", data, 17), string.unpack(">I4", data, 21)
	end
	local badTex = {}
	for set, maps in manifest.Textures do
		for kind, rel in maps do
			local path = "assets/nave/" .. rel
			if not fs.isFile(path) then
				table.insert(badTex, rel .. " (falta)")
			else
				local w, h = pngSize(path)
				if w > 1024 or h > 1024 or w ~= h then
					table.insert(badTex, ("%s %dx%d"):format(rel, w, h))
				end
			end
		end
		if set ~= "lod" and not (maps.color and maps.normal and maps.rugosidad and maps.metal) then
			table.insert(badTex, set .. " sin sus 4 mapas")
		end
	end
	check(#badTex == 0, "texturas PBR (color, normal, rugosidad, metal) de cada juego, ≤ 1024 px" .. (if #badTex > 0 then ": " .. table.concat(badTex, ", ") else ""))
	local same = #Malla.Pieces == #manifest.Pieces
	for i, p in Malla.Pieces do
		local m = manifest.Pieces[i]
		if not m or m.Name ~= p.Name or m.Tris ~= p.Tris or math.abs(m.Size[1] - p.Size.X) > 0.01 then
			same = false
		end
	end
	check(same and #Malla.Engines == 2, "shared/AirCombat/NaveMalla es el manifest exportado (piezas, tamaños, triángulos) y la nave tiene DOS motores")

	-- 3. Con la malla cargada (un doble de AssetLoader.download): la MISMA API para el resto del juego
	local fakeIds = { Completa = "", Piezas = {}, Texturas = { casco_color = "rbxassetid://11", casco_normal = "rbxassetid://12", casco_rugosidad = "rbxassetid://13", casco_metal = "rbxassetid://14", alas_color = "rbxassetid://21", motores_color = "rbxassetid://31", lod_color = "rbxassetid://41" } }
	local assets = {}
	for i, p in ipairs(Malla.Pieces) do
		fakeIds.Piezas[p.Name] = "rbxassetid://" .. (1000 + i)
		local m = Instance.new("Model")
		local mp = Instance.new("MeshPart")
		mp.Name = "Malla_" .. p.Name
		mp.Parent = m
		assets[1000 + i] = m
	end
	local downloads = 0
	local function download(id: number)
		downloads += 1
		local a = assets[id]
		return a and a:Clone()
	end
	check(NaveLoader.hasIds(fakeIds), "con ids de piezas hay algo que cargar")
	local folder, okWhy = NaveLoader.prepare(fakeIds, download)
	check(folder ~= nil and okWhy == "ok" and downloads == #Malla.Pieces, ("prepara la plantilla con una MeshPart por pieza (%d descargas)"):format(downloads))
	if folder then
		local hull = folder:FindFirstChild("Fuselaje")
		local sa = hull and hull:FindFirstChildOfClass("SurfaceAppearance")
		check(hull and hull:IsA("MeshPart") and ((sa and sa.ColorMap == "rbxassetid://11" and sa.NormalMap == "rbxassetid://12") or hull.TextureID == "rbxassetid://11"), "el fuselaje lleva sus texturas (SurfaceAppearance o, si no se puede, TextureID)")
		local glass = folder:FindFirstChild("Cabina")
		check(glass and glass.Material == Enum.Material.Glass and glass.Transparency > 0.2, "la cabina de malla es de cristal tintado")
		check(folder:FindFirstChild("BrilloAzul").Material == Enum.Material.Neon and folder:FindFirstChild("BrilloRojo").Material == Enum.Material.Neon, "las tiras que brillan (azul y roja) son Neon")
		ShipModel.setMeshTemplate(folder)
		local cf = CFrame.new(50, 3000, -20) * CFrame.Angles(0, 0.7, 0)
		local ship = ShipModel.build("Caza", cf)
		check(ShipModel.meshReady() and ship:GetAttribute("NaveVisual") == "Malla", "con plantilla, «Caza» se construye con la malla")
		local root = ship.PrimaryPart
		local n, loose, colliding, names = 0, {}, {}, {}
		for _, d in ship:GetChildren() do
			names[d.Name] = (names[d.Name] or 0) + 1
			if d:IsA("BasePart") and d ~= root then
				n += 1
				local w = d:FindFirstChildOfClass("WeldConstraint")
				if not w or w.Part0 ~= root or d.Anchored then
					table.insert(loose, d.Name)
				end
				if d.CanCollide then
					table.insert(colliding, d.Name)
				end
			end
		end
		check(root and root.Name == "Root" and root.Anchored and root.Transparency == 1, "Root invisible y anclado (el mismo de siempre)")
		check(#loose == 0 and #colliding == 0, "todo soldado al Root y sin choques" .. (if #loose > 0 then ": " .. table.concat(loose, ", ") else ""))
		check(n <= 25, ("pocas piezas (%d): la malla trae el detalle"):format(n))
		local seat = ship:FindFirstChild("ShipSeat")
		check(seat and seat.ClassName == "Seat" and (cf:ToObjectSpace(seat.CFrame).Position - Malla.Seat).Magnitude < 0.01, "asiento «ShipSeat» en la cabina")
		check(names.Escape == 2 and names.Llama == 2 and names.EstelaMotor == nil and #ship:FindFirstChild("Escape"):GetChildren() >= 3, "dos motores con brillo («Escape»), llama («Llama»), estela y luz (los anima AirCombatFx)")
		check(names.LuzNavIzq == 1 and names.LuzNavDer == 1 and names.LuzCola == 1 and cf:ToObjectSpace(ship:FindFirstChild("LuzNavIzq").CFrame).Position.X < -10, "luces de navegación en las puntas de las alas y en la cola")
		local gear = ship:FindFirstChild(ShipModel.Gear)
		check(gear and gear:IsA("MeshPart") and gear.Transparency == 1, "tren de aterrizaje de malla («TrenPata»), escondido hasta cerca del suelo")
		local lodPart = ship:FindFirstChild("NaveLOD")
		check(lodPart and lodPart.Transparency == 1 and lodPart:GetAttribute("NaveLOD") and ship:FindFirstChild("Fuselaje"):GetAttribute("NaveAlta"), "la versión lejana va dentro, escondida (la elige cada cliente)")
		local hullAt = cf:ToObjectSpace(ship:FindFirstChild("Fuselaje").CFrame).Position
		local plan = byName.Fuselaje.Center
		check((hullAt - Vector3.new(plan[1], plan[2], plan[3])).Magnitude < 0.01 and ship:FindFirstChild("Fuselaje").Size.Z > 25, "cada pieza en su sitio y con su tamaño (centro y caja del manifest)")
		local seatTop = cf:ToObjectSpace(seat.CFrame).Position.Y + 0.2
		local glassP = byName.Cabina
		check(seatTop + 3.7 <= glassP.Center[2] + glassP.Size[2] / 2 + 0.05 and seatTop < 0, "el piloto va dentro: la cabeza bajo la cabina de cristal")
		-- 4. Las naves que ya estaban hechas con piezas se cambian (sin tocar el asiento ni el Root)
		ShipModel.setMeshTemplate(nil)
		local old = ShipModel.build("Caza", cf)
		local oldSeat, oldRoot = old:FindFirstChild("ShipSeat"), old.PrimaryPart
		check(not ShipModel.upgrade(old), "sin plantilla no se cambia nada")
		ShipModel.setMeshTemplate(folder)
		check(ShipModel.upgrade(old) and old:GetAttribute("NaveVisual") == "Malla" and old:FindFirstChild("ShipSeat") == oldSeat and old.PrimaryPart == oldRoot and old:FindFirstChild("Motores") and old:FindFirstChild("Gondola" .. "Izq") == nil, "ShipModel.upgrade: de piezas a malla con el mismo Root y el mismo asiento")
		local escapes = 0
		for _, d in old:GetChildren() do
			if d.Name == "Escape" then
				escapes += 1
			end
		end
		check(escapes == 2 and old:FindFirstChild("ShipSeat") and #old:GetChildren() <= 26, "y sin piezas repetidas")
		-- 5. LOD: la tuya siempre de cerca; las demás, lejos (antes en el móvil)
		check(ShipModel.lodLevel(5000, true, "Low") == "Alta", "tu nave: siempre la de alta")
		check(ShipModel.lodLevel(100, false, "Low") == "Baja" and ShipModel.lodLevel(100, false, "High") == "Alta" and ShipModel.lodLevel(300, false, "High") == "Baja" and ShipModel.lodLevel(100, false, nil) == "Alta", "las de los demás: la lejana a partir de LodDistance (Low 70, Medium 150, High 260)")
		local okLod = pcall(ShipModel.applyLod, ship, "Baja")
		check(okLod and lodPart.Transparency == 0 and ship:GetAttribute("NaveLodVista") == "Baja", "applyLod enseña la NaveLOD de lejos")
		pcall(ShipModel.applyLod, ship, "Alta")
		check(lodPart.Transparency == 1, "y la quita de cerca")
		ShipModel.setMeshTemplate(nil)
		check(ShipModel.build("Caza", cf):GetAttribute("NaveVisual") == "Piezas", "sin plantilla otra vez: vuelve la de piezas")
	end
	-- 6. Fallos de carga: respaldo
	local partial = table.clone(fakeIds.Piezas)
	partial.Motores = nil
	local f2, why2 = NaveLoader.prepare({ Completa = "", Piezas = partial, Texturas = {} }, download)
	check(f2 == nil and string.find(why2, "Motores", 1, true) ~= nil, "si falta una pieza imprescindible: sin plantilla (sigue la de piezas)")
	local f3 = NaveLoader.prepare(fakeIds, function()
		error("HTTP 403")
	end)
	check(f3 == nil, "si la descarga falla: sin plantilla (sigue la de piezas), sin error")
	-- 7. El Model completo de la fase 3 (scripts/nave/compose.luau)
	local Compose = require("./nave/compose")
	local raw = Instance.new("Model")
	local mp = Instance.new("MeshPart")
	mp.Parent = raw
	local bytes = roblox.serializeModel({ raw })
	local full, missing = Compose.build(manifest.Pieces, { Fuselaje = bytes, Alas = bytes }, Compose.readTextures("casco_color=rbxassetid://5\ncasco_normal=rbxassetid://6\n"))
	local fh = full:FindFirstChild("Fuselaje")
	local fsa = fh and fh:FindFirstChildOfClass("SurfaceAppearance")
	check(fh and fsa and fsa.ColorMap == "rbxassetid://5" and fsa.NormalMap == "rbxassetid://6" and #missing == #manifest.Pieces - 2, "compose.luau: MeshPart en su sitio con SurfaceAppearance (los mapas solo se pueden poner así)")
	local f4 = NaveLoader.prepare({ Completa = "rbxassetid://77", Piezas = {}, Texturas = {} }, function(id)
		return if id == 77 then full else nil
	end)
	check(f4 == nil, "un Model completo al que le faltan piezas no vale (respaldo)")
	-- 8. El script de subida: nunca enseña la clave y escribe NaveAssetIds
	local up = fs.readFile("scripts/upload-nave.sh")
	local keyLines = {}
	for line in string.gmatch(up, "[^\n]+") do
		if string.find(line, "ROBLOX_API_KEY", 1, true) and not string.find(line, "^%s*#") then
			table.insert(keyLines, line)
		end
	end
	local safeKey = true
	for _, line in keyLines do
		local ok = string.find(line, 'printf \'x-api-key: %s\\n\' "$ROBLOX_API_KEY" > "$HEADERS"', 1, true) or string.find(line, '[ -z "${ROBLOX_API_KEY:-}" ]', 1, true) or string.find(line, "export ROBLOX_API_KEY=…", 1, true) or string.find(line, "Falta ROBLOX_API_KEY", 1, true)
		if not ok then
			safeKey = false
			print("     línea con la clave: " .. line)
		end
	end
	check(safeKey and string.find(up, "set +x", 1, true) and string.find(up, 'chmod 600 "$HEADERS"', 1, true) and not string.find(up, "x-api-key: $", 1, true), "upload-nave.sh: la clave solo va a un archivo de cabeceras (chmod 600), nunca se enseña")
	check(string.find(up, "src/shared/AirCombat/NaveAssetIds.luau", 1, true) and string.find(up, '"assetType":"%s"', 1, true) and string.find(up, "model/fbx", 1, true) and string.find(up, "Decal image/png", 1, true), "upload-nave.sh: texturas como Decal, piezas FBX como Model y escribe NaveAssetIds")
	-- 9. La ficha de la nave (puerto y hangar)
	local card = ShipInfo.card()
	check(string.find(card, "HX-7 HALCÓN", 1, true) and string.find(card, "1.250 km/h", 1, true) and string.find(card, "12.000 kg", 1, true) and string.find(card, "ESCUDOS  100%", 1, true) and string.find(card, "ESTRUCTURA  100%", 1, true), "ficha: HX-7 Halcón, 1.250 km/h, escudos y estructura 100%, 12.000 kg")
	check(ShipInfo.stats({ Hull = 50, MaxHull = 100, Shield = 15, MaxShield = 60 })[3].Value == "50%" and ShipInfo.stats({ Hull = 50, MaxHull = 100, Shield = 15, MaxShield = 60 })[2].Value == "25%", "escudos y estructura salen del estado de verdad")
	local bad = {}
	for _, path in { "src/shared/AirCombat/NaveMalla.luau", "src/shared/AirCombat/ShipInfo.luau", "assets/nave/manifest.json", "scripts/nave/diseno.py", "scripts/nave/nave_blender.py", "scripts/upload-nave.sh" } do
		local text = string.lower(fs.readFile(path))
		if string.find(text, "nova", 1, true) or string.find(text, "nv-7", 1, true) then
			table.insert(bad, path)
		end
	end
	check(#bad == 0, "ningún nombre de la imagen de referencia (designación propia: HX-7)" .. (if #bad > 0 then ": " .. table.concat(bad, ", ") else ""))
	local gen = fs.readFile("scripts/nave/diseno.py")
	check(string.find(gen, "PRESETS", 1, true) and string.find(gen, '"ejemplo_alien"', 1, true), "el generador de Blender va por parámetros (presets: otras naves con el mismo código)")
end

---------------------------------------------------------------------
print("\n✨ HUD fiel a la referencia: sprites con brillo (UI/HudArt, assets/hud, scripts/upload-hud.sh)")
---------------------------------------------------------------------
do
	local serde = require("@lune/serde")
	local HudArt = L.load("src/client/UI/HudArt")
	local Hud = L.load("src/client/UI/AirCombatHud")
	-- 1. Los sprites: existen, ≤ 1024 px, poco peso y los mismos números que UI/HudArt
	local manifest = serde.decode("json", fs.readFile("assets/hud/manifest.json"))
	local bad = {}
	for _, name in HudArt.Files do
		local f = manifest.Files[name]
		if not f or not fs.isFile("assets/hud/" .. name .. ".png") or f.W > 1024 or f.H > 1024 then
			table.insert(bad, name)
		end
	end
	local nFiles = 0
	for _ in manifest.Files do
		nFiles += 1
	end
	check(#bad == 0 and nFiles == #HudArt.Files, ("%d sprites en assets/hud, todos ≤ 1024 px%s"):format(nFiles, if #bad > 0 then ": mal " .. table.concat(bad, ", ") else ""))
	check(manifest.TotalBytes < 2.5 * 1024 * 1024, ("los sprites pesan poco (%d KB)"):format(math.floor(manifest.TotalBytes / 1024)))
	local A, MA = HudArt.Arc, manifest.Arc
	check(A.FrameW == MA.FrameW and A.FrameH == MA.FrameH and A.Cols == MA.Cols and A.Frames == MA.Frames and A.Segments == MA.Segments and A.From == MA.From and A.To == MA.To, "arcos: el atlas de UI/HudArt es el del generador (21 estados de 128x256, 8 columnas)")
	check(HudArt.Cool.Frame == manifest.Cool.Frame and HudArt.Cool.Frames == manifest.Cool.Frames and HudArt.Compass.W == manifest.Compass.W and HudArt.Compass.PxPerDeg == manifest.Compass.PxPerDeg and HudArt.Compass.Window == manifest.Compass.Window, "recarga y brújula: los mismos números que el generador")
	local sameIcons = #HudArt.Icon.Names == #manifest.Icon.Names and HudArt.Icon.Size == manifest.Icon.Size
	for i, n in HudArt.Icon.Names do
		sameIcons = sameIcons and manifest.Icon.Names[i] == n
	end
	check(sameIcons and #HudArt.Icon.Names == 32, "iconos: los 32 en el mismo orden (escudo, energía, cristal, cubo, mineral, misil, láser, camuflaje, salto, hiper, dron, tren, flaps, frenos, cámara…)")
	local sameFrames = true
	for name, def in HudArt.Frames do
		local m = manifest.Frames[name]
		sameFrames = sameFrames and m ~= nil and m.Pad == def.Pad and m.Size[1] == def.Size[1] and m.Size[2] == def.Size[2]
		for i = 1, 4 do
			sameFrames = sameFrames and m.Slice[i] == def.Slice[i]
		end
	end
	check(sameFrames, "marcos 9-slice: recortes y márgenes iguales a los del generador")
	local glyphsOk = true
	for _, icon in HudArt.GlyphIcon do
		glyphsOk = glyphsOk and HudArt.iconIndex(icon) ~= nil
	end
	for _, s in ShipAbilities.Slots or {} do
		glyphsOk = glyphsOk and (s.Glyph == nil or HudArt.GlyphIcon[s.Glyph] ~= nil)
	end
	check(glyphsOk, "cada glifo de las ranuras (nave y avión) tiene su icono dibujado")
	-- 2. Los ids: vacío hasta que se suba (solo la sesión que publica)
	local Ids = L.load("src/shared/HudTextureIds")
	local idsOk = type(Ids) == "table"
	for k, v in Ids do
		idsOk = idsOk and table.find(HudArt.Files, k) ~= nil and type(v) == "string" and string.match(v, "^rbxassetid://%d+$") ~= nil
	end
	check(idsOk, "shared/HudTextureIds: una tabla nombre -> rbxassetid (vacía hasta scripts/upload-hud.sh)")
	-- 3. Cuentas
	check(HudArt.frameIndex(0) == 0 and HudArt.frameIndex(1) == 20 and HudArt.frameIndex(0.5) == 10 and HudArt.frameIndex(-3) == 0 and HudArt.frameIndex(7) == 20 and HudArt.frameIndex(0 / 0) == 0, "fotograma del arco: 0..20, con tope (y sin NaN)")
	local o1, o12 = HudArt.arcOffset(1), HudArt.arcOffset(0.6)
	check(o1.X == 4 * 128 and o1.Y == 2 * 256 and o12.X == 4 * 128 and o12.Y == 256, "dónde está cada fotograma en el atlas (fila y columna)")
	check(HudArt.coolOffset(0).X == 0 and HudArt.coolOffset(1).X == 4 * 96 and HudArt.coolOffset(1).Y == 2 * 96, "recarga: barrido de reloj, de lista (0) a recién usada (1)")
	check(HudArt.iconOffset("escudo").X == 0 and HudArt.iconOffset("chispas").X == 7 * 128 and HudArt.iconOffset("chispas").Y == 3 * 128 and HudArt.iconOffset("nada") == nil, "iconos: posición en el atlas (y nil si no existe)")
	check(HudArt.compassOffset(60) == 0 and HudArt.compassOffset(0) == 600 and HudArt.compassOffset(359) + HudArt.Compass.Window * HudArt.Compass.PxPerDeg <= HudArt.Compass.W, "brújula: la ventana de 120° nunca se sale de la cinta")
	local G = HudArt.GaugeColors
	check(HudArt.gaugeColor("Shield", 0.9) == G.Shield and HudArt.gaugeColor("Shield", 0.5) == G.Warn and HudArt.gaugeColor("Hull", 0.4) == G.Warn and HudArt.gaugeColor("Hull", 0.25) == G.Danger and HudArt.gaugeColor("Energy", 0.05) == G.Danger and HudArt.gaugeColor("Hull", 0.51) == G.Hull, "colores: el suyo; naranja ≤ 50 %, rojo ≤ 25 %")
	check(HudArt.gaugeColor("Speed", 0.1) == G.Speed and HudArt.gaugeColor("Speed", 0.5, { Boost = true }) == G.Boost and HudArt.gaugeColor("Speed", 0.5, { Stall = true }) == G.Danger, "velocidad: cian (lenta no es mala), naranja con impulso, roja en pérdida")
	local v1 = HudArt.approach(0, 1, 0.1)
	local v = 0
	for _ = 1, 60 do
		v = HudArt.approach(v, 1, 0.1)
	end
	check(HudArt.approach(nil, 0.7, 0.1) == 0.7 and v1 > 0 and v1 < 1 and v == 1 and HudArt.approach(0.5, 0.2, 0.1) < 0.5, "relleno animado: la primera vez se pone; luego sube y baja suave y llega")
	check(HudArt.plain("✨ 7") == "7" and HudArt.plain("⛏ 3/40") == "3/40" and HudArt.plain("12") == "12", "con iconos, sin el emoji del principio")
	-- 4. Sin ids: el aspecto de siempre (ninguna imagen de sprite, rayitas y marcos)
	HudArt.setIds({})
	local pg = roblox.Instance.new("Folder")
	local plain = Hud.new(pg, false)
	local sprites = 0
	for _, d in pg:GetDescendants() do
		if d:IsA("ImageLabel") and d.Name ~= "Avatar" then
			sprites += 1
		end
	end
	check(sprites == 0 and next(plain.Art) == nil and plain.Zones.A.BackgroundTransparency < 1 and plain.Arcs.Speed[1].Visible, "sin ids (HudTextureIds vacío): ningún sprite, marcos y rayitas de siempre")
	-- 5. Con ids: los sprites
	local fake = {}
	for i, name in HudArt.Files do
		fake[name] = "rbxassetid://" .. tostring(9000 + i)
	end
	HudArt.setIds(fake)
	local pg2 = roblox.Instance.new("Folder")
	local view = Hud.new(pg2, false)
	local marco = view.Zones.A:FindFirstChild("Marco")
	check(marco and marco:IsA("ImageLabel") and marco.ScaleType == roblox.Enum.ScaleType.Slice and marco.SliceCenter.Min.X == 30 and marco.Image == fake.marco_panel and view.Zones.A.BackgroundTransparency == 1, "con ids: paneles con marco 9-slice (SliceCenter) en vez de la caja plana")
	check(view.Art.ArcSpeed and view.Art.ArcBoost and view.Art.ArcShield and view.Art.ArcHull and not view.Arcs.Speed[1].Visible and view.Art.ArcSpeed.ImageRectSize.X == 128, "con ids: arcos con brillo (velocidad, impulso, escudo y estructura) en vez de las rayitas")
	Hud.set(view, { Speed = 750, SpeedMax = 1500, Boost = 0.8, BoostReady = true, Shield = 15, MaxShield = 60, Hull = 45, MaxHull = 100, Missiles = 3, MaxMissiles = 6, Overheated = false, Wave = 0, Score = 0, Objective = "Vuelo libre", Mode = "Space", Energy = 55, MaxEnergy = 100, FlightMode = "Combat" })
	local so = view.Art.ArcSpeed.ImageRectOffset
	check(so == HudArt.arcOffset(0.5) and view.Art.ArcShield.ImageRectOffset == HudArt.arcOffset(0.25) and view.Art.ArcShield.ImageColor3 == G.Danger and view.Art.ArcHull.ImageColor3 == G.Warn and view.Art.ArcSpeed.ImageColor3 == G.Speed, "arcos: el fotograma del valor; escudo al 25 % rojo, estructura al 45 % naranja")
	view.GaugeClock = os.clock() - 0.1
	Hud.set(view, { Speed = 750, SpeedMax = 1500, Boost = 0.8, BoostReady = true, Shield = 60, MaxShield = 60, Hull = 45, MaxHull = 100, Missiles = 3, MaxMissiles = 6, Overheated = false, Wave = 0, Score = 0, Objective = "Vuelo libre", Mode = "Space", Energy = 55, MaxEnergy = 100, FlightMode = "Combat" })
	check(view.Gauges.Shield > 0.25 and view.Gauges.Shield < 1, ("el escudo se rellena animado (%.2f de camino a 1)"):format(view.Gauges.Shield))
	Hud.setSlots(view, ShipAbilities.slotViews({ Energy = 100, Weapon = "Laser", Missiles = 4, Cool = { Quantum = 6 } }), "Keyboard")
	local s3, s6 = view.Slots[3], view.Slots[6]
	check(s3.Glyph:IsA("ImageLabel") and s3.Glyph:GetAttribute("Icon") == "laser" and s3.Tile.Image == fake.marco_ranura_sel and view.Slots[1].Tile.Image == fake.marco_ranura, "ranuras: icono dibujado del atlas y la elegida con el marco luminoso")
	check(s6.Sweep and s6.Sweep.ImageRectOffset ~= HudArt.coolOffset(0) and not s6.Cool.Visible, "recarga: barrido de reloj (no la cortina)")
	Hud.setCompass(view, 90, 120)
	check(view.Nav.Tape and view.Nav.Tape.ImageRectOffset.X == HudArt.compassOffset(90), "brújula: la cinta con brillo se mueve con el rumbo")
	Hud.setProfile(view, { UserId = 1, Name = "Piloto", Level = 100, Money = "10.000.014 €", Chispas = 7, Resources = { { Text = "⛏ 3/40" }, { Text = "⛽ 80%", Icon = "combustible" } } })
	local P = view.Profile
	check(P.Chispas.Text == "7" and P.Res[3].Text == "80%" and P.ResIcons[3]:GetAttribute("Icon") == "combustible" and view.Art.AvatarRing and view.Art.Rank and view.Art.Coin, "perfil: retrato con aro y rango, moneda y recursos con su icono")
	check(view.Zones.D:FindFirstChild("Disco") and view.Art.Sweep and view.Zones.Jump:FindFirstChild("Vortice") and view.Overlay:FindFirstChild("Mira", true) and view.Art.Emblem and #(view.Art.ShipSilhouettes or {}) == 2, "radar con barrido, vórtice del salto, mira, emblema de HIPERVELOCIDAD y siluetas")
	Hud.setVehicle(view, "Plane")
	check(not view.Art.ArcShield.Visible and view.Art.ShipSilhouettes[1].Image == fake.silueta_avion and view.Art.Me:GetAttribute("Icon") == "avion", "avión: sin arco de escudo; silueta y flecha del radar del avión")
	Hud.setVehicle(view, "Ship")
	check(view.Art.ArcShield.Visible and view.Art.ShipSilhouettes[1].Image == fake.silueta_nave, "y la nave vuelve a tener las suyas")
	local pg3 = roblox.Instance.new("Folder")
	local okTouch, tview = pcall(Hud.new, pg3, true, "Plane")
	check(okTouch and tview.Art.ArcSpeed ~= nil, "móvil con sprites: se construye igual (compacto)" .. (if okTouch then "" else ": " .. tostring(tview)))
	-- 6. Lo que se montaba en la captura del avión: perfil y radar
	for _, t in { false, true } do
		local hv = if t then tview else view
		local W = hv.Zones.A.Size.X.Offset
		local lv, nm, mo = hv.Profile.Level, hv.Profile.Name, hv.Profile.Money
		local moneyLeft = W - 12 - mo.Size.X.Offset
		check(lv.Position.X.Offset + lv.Size.X.Offset <= nm.Position.X.Offset and nm.Position.X.Offset + nm.Size.X.Offset <= moneyLeft and mo.TextScaled and lv.TextScaled,
			("%s: «Nv.», nombre y dinero no se montan (el dinero encoge la letra para caber)"):format(if t then "móvil" else "ordenador"))
		local rl = hv.RadarLabel
		check(rl.AnchorPoint.X == 1 and rl.Position.X.Scale <= 0.15 and rl.Position.Y.Scale == 1, ("%s: «RADAR x km» fuera del círculo (nunca encima de la N)"):format(if t then "móvil" else "ordenador"))
	end
	HudArt.setIds({})
	-- 7. Tocar con el dedo: todo lo que se toca mide ≥ 44 pt (32 en 640x360)
	for _, case in { { 932, 430 }, { 844, 390 }, { 640, 360 } } do
		local l = SHL.compute(Vector2.new(case[1], case[2]), { Touch = true, Inset = 58 })
		local need = if case[1] <= 700 then 32 else 44
		local small = {}
		for _, n in { "Help", "Jump", "Target", "Speed" } do
			local r = l.Zones[n]
			if r and math.min(r.W, r.H) * l.Scale < need then
				table.insert(small, ("%s %d pt"):format(n, math.floor(math.min(r.W, r.H) * l.Scale)))
			end
		end
		if l.SlotSize * l.Scale < need then
			table.insert(small, "ranuras")
		end
		check(#small == 0, ("%dx%d: «?», SALTO, OBJETIVO, el modo y las ranuras se tocan bien (≥ %d pt)%s"):format(case[1], case[2], need, if #small > 0 then ": " .. table.concat(small, ", ") else ""))
	end
	check(tview.Zones.Speed:FindFirstChild("TocarModo") and tview.HelpPanel:FindFirstChild("Cerrar").Size.X.Offset >= 90, "móvil: todo el hueco de la velocidad cambia el modo; el ✕ de la ayuda es grande")
	-- 8. La subida: nunca enseña la clave y escribe HudTextureIds
	local up = fs.readFile("scripts/upload-hud.sh")
	local safe = true
	for line in string.gmatch(up, "[^\n]+") do
		if string.find(line, "ROBLOX_API_KEY", 1, true) and not string.find(line, "^%s*#") then
			local ok = string.find(line, 'printf \'x-api-key: %s\\n\' "$ROBLOX_API_KEY" > "$HEADERS"', 1, true) or string.find(line, '[ -z "${ROBLOX_API_KEY:-}" ]', 1, true) or string.find(line, "export ROBLOX_API_KEY=…", 1, true) or string.find(line, "Falta ROBLOX_API_KEY", 1, true)
			if not ok then
				safe = false
				print("     línea con la clave: " .. line)
			end
		end
	end
	check(safe and string.find(up, "set +x", 1, true) and string.find(up, 'chmod 600 "$HEADERS"', 1, true) and string.find(up, "set -euo pipefail", 1, true) and not string.find(up, "echo \"$ROBLOX_API_KEY", 1, true), "upload-hud.sh: la clave solo va a un archivo de cabeceras (chmod 600), nunca se enseña")
	check(string.find(up, 'IDS="src/shared/HudTextureIds.luau"', 1, true) and string.find(up, "assets/hud/*.png", 1, true) and string.find(up, "scripts/hud/gen_hud.py", 1, true) and string.find(up, '"assetType":"Decal"', 1, true), "upload-hud.sh: sube assets/hud como Decal y escribe shared/HudTextureIds")
	local names = {}
	for _, path in { "scripts/hud/gen_hud.py", "scripts/upload-hud.sh", "src/client/UI/HudArt.luau", "src/shared/HudTextureIds.luau", "assets/hud/manifest.json" } do
		if string.find(string.lower(fs.readFile(path)), "nova", 1, true) then
			table.insert(names, path)
		end
	end
	check(#names == 0, "ningún nombre de la imagen de referencia en los sprites ni en su código" .. (if #names > 0 then ": " .. table.concat(names, ", ") else ""))
end

---------------------------------------------------------------------
print("")
if failures > 0 then
	print(("❌ test-espacio-aaa: %d fallos"):format(failures))
	process.exit(1)
end
print("✅ test-espacio-aaa: todo correcto")
