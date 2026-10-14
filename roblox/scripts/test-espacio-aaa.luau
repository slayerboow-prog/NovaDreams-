-- Prueba del Espacio «AAA» (fases 2 a 6: docs/espacio-aaa/diseno.md), con Lune (sin Roblox).
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
print("")
if failures > 0 then
	print(("❌ test-espacio-aaa: %d fallos"):format(failures))
	process.exit(1)
end
print("✅ test-espacio-aaa: todo correcto")
