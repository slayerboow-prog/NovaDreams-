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
			if name ~= "Quantum" and SHL.overlaps(r, center) then
				table.insert(covering, name)
			end
		end
		check(#covering == 0, ("%dx%d: el centro (la mira y el combate) queda libre%s"):format(w, h, if #covering > 0 then ": " .. table.concat(covering, ", ") else ""))
		local need = if w == 640 then 32 else 44
		local slotPt = l.SlotSize * l.Scale
		if touch then
			check(slotPt >= need, ("%dx%d: las 8 ranuras se pueden tocar (%d pt)"):format(w, h, math.floor(slotPt)))
			check(l.Zones.G == nil and l.Zones.I == nil, ("%dx%d: en el móvil, sin listas de teclas (palanca y botones)"):format(w, h))
			check(l.Buttons.Fuego and l.Buttons.EsquivaNave and l.Buttons.Fuego.W >= l.Buttons.Misil.W and l.Buttons.Fuego.W >= l.Buttons.EsquivaNave.W, ("%dx%d: DISPARO es el botón más grande; ESQUIVA tiene su hueco"):format(w, h))
		else
			check(l.Zones.G ~= nil and l.Stick == nil, ("%dx%d: en el ordenador, teclas y sin palanca táctil gigante"):format(w, h))
		end
		local d, e = l.Zones.D, l.Zones.E
		check(d.X + d.W <= l.Canvas.X and e.Y >= d.Y + d.H and e.X + e.W <= l.Canvas.X, ("%dx%d: radar arriba a la derecha y misiones debajo"):format(w, h))
	end
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
		for _, n in { "A", "B", "C", "D", "E", "G", "H", "J", "Prompt", "Quantum" } do
			if not view.Zones[n] then
				table.insert(zones, n)
			end
		end
		check(#zones == 0, "todas las zonas existen" .. (if #zones > 0 then ": faltan " .. table.concat(zones, ", ") else ""))
		Hud.set(view, { Speed = 284.4, Boost = 0.5, BoostReady = true, Shield = 30, MaxShield = 60, Hull = 25, MaxHull = 100, Missiles = 3, MaxMissiles = 6, Overheated = false, Wave = 0, Score = 0, Objective = "Vuelo libre", Mode = "Space", Energy = 55, MaxEnergy = 100, Weapon = "Laser", Heat = 0.4, FlightMode = "Cruise", Assist = false })
		local V = view.Values
		check(V.Speed.Text == "284" and V.Shield.Text == "30" and V.Hull.Text == "25" and V.Missiles.Text == "3/6" and V.Energy.Text == "55%" and V.Weapon.Text == "LÁSER", "el panel enseña lo que manda el servidor (escudo, casco, misiles, energía, arma)")
		check(near(view.Bars.Shield.Size.X.Scale, 0.5) and near(view.Bars.Energy.Size.X.Scale, 0.56, 0.02) and view.Bars.Hull.BackgroundColor3.R > view.Bars.Hull.BackgroundColor3.G, "barras al valor (y el casco crítico en rojo)")
		check(view.Chips.Mode.Text == "CRUCERO · LIBRE", "modo de vuelo y asistencia a la vista")
		Hud.setProfile(view, { UserId = 1, Name = "Piloto", Level = 12, Money = "$4.200", Chispas = 7 })
		check(view.Profile.Name.Text == "Piloto" and view.Profile.Level.Text == "Nv. 12" and view.Profile.Chispas.Text == "✨ 7" and string.find(view.Profile.Avatar.Image, "AvatarHeadShot", 1, true) ~= nil, "perfil: avatar real, nombre, nivel, dinero y Chispas")
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
		Hud.radar(view, blips, 1400, 0)
		local shown = 0
		for _, b in view.Blips do
			if b.Visible then
				shown += 1
			end
		end
		check(shown == 2 and view.Blips[1].BackgroundColor3.R > 0.9, "radar: un punto por cosa detectada, el enemigo en rojo")
		Hud.setMissions(view, { { Kind = "PRINCIPAL", Title = "Saga 2", Step = "Ve a Tefra", Right = "12 km" }, { Kind = "EVENTO", Title = "⚠ Patrulla" } })
		check(view.Missions[1].Row.Visible and view.Missions[1].Title.Text == "Saga 2" and view.Missions[2].Kind.Text == "EVENTO" and not view.Missions[3].Row.Visible, "misiones: principal y evento, con distancia")
		Hud.showQuantum(view, { { Id = "Estacion_Cenit", Name = "Estación Cénit", Kind = "Estación", Dist = "2 km", Cost = 30, Ok = true }, { Id = "Campo_Brasa", Name = "Campo Brasa", Kind = "Campo", Dist = "1 km", Cost = 26, Ok = false, Reason = "Sin descubrir" } }, "Energía 80", function() end, function() end)
		check(Hud.quantumOpen(view) and #view.Quantum.Rows == 2, "selector del salto: lista de destinos con distancia y coste")
		Hud.hideQuantum(view)
		check(not Hud.quantumOpen(view), "y se cierra")
		local texts = Hud.texts({ Speed = 0, Boost = 0, BoostReady = true, Shield = 0, MaxShield = 60, Hull = 0, MaxHull = 100, Missiles = 0, MaxMissiles = 6, Overheated = false, Wave = 0, Score = 0, Objective = "", Mode = "Space", Alert = "⚔ EN COMBATE" })
		check(texts.Warning == "⚔ EN COMBATE", "avisos (zona J) solo cuando hacen falta")
	end
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
print("")
if failures > 0 then
	print(("❌ test-espacio-aaa: %d fallos"):format(failures))
	process.exit(1)
end
print("✅ test-espacio-aaa: todo correcto")
