-- Prueba del manejo de las armas en el móvil (estilo shooter móvil) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-shooter.luau
--
-- Comprueba shared/AimAssist (ayuda de apuntado, fricción y sensibilidad de la cámara con el dedo):
--   * elige el objetivo válido más cercano a la mira dentro de un cono pequeño (más ancho de cerca)
--   * ignora a quien está detrás de una pared, fuera del cono o demasiado lejos
--   * apunta al torso (nunca a la cabeza) y gira poco a poco (más apuntando; un tirón al pulsar Apuntar)
--   * solo con el dedo o el mando: con ratón y teclado, nada
--   * solo objetivos válidos: ni la gente de la calle, ni agentes, ni los de tu equipo, ni bebés
--   * apuntando, y con la mira encima de alguien, arrastrar el dedo gira menos
-- Y, en el código, que WeaponController lo usa así (y que el servidor sigue mandando).

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, Vector2 = roblox.Vector3, roblox.Vector2
local env = setmetatable({ Vector3 = Vector3, Vector2 = Vector2 }, { __index = getfenv(1) })
local AimAssist = luau.load(fs.readFile("src/shared/AimAssist.luau"), { debugName = "AimAssist", environment = env })()

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local C = AimAssist.Config
local origin = Vector3.new(0, 5, 0)
local look = Vector3.new(0, 0, -1) -- mirando al norte

-- Un punto a `distance` studs y `degrees` grados a la derecha de la mira
local function at(distance: number, degrees: number, name: string): { [string]: any }
	local r = math.rad(degrees)
	return { Name = name, Point = origin + Vector3.new(math.sin(r), 0, -math.cos(r)) * distance }
end

print("▶ Elegir el objetivo")
do
	local a = at(20, 3, "A")
	local b = at(20, 1, "B")
	local best = AimAssist.pick(origin, look, { a, b })
	check(best == b, "de dos en el cono, el más cercano a la mira")
	local hidden = AimAssist.pick(origin, look, { a, b }, function(c)
		return c ~= b -- (B detrás de una pared)
	end)
	check(hidden == a, "detrás de una pared no cuenta: pasa al siguiente que se ve")
	local none = AimAssist.pick(origin, look, { b }, function()
		return false
	end)
	check(none == nil, "si ninguno se ve, nada")
	check(AimAssist.pick(origin, look, { at(20, 20, "lejos del centro") }) == nil, "fuera del cono (20°), nada")
	check(AimAssist.pick(origin, look, { at(8, 7.5, "cerca") }) ~= nil, ("de cerca el cono es más ancho (%d°)"):format(C.ConeNear))
	check(AimAssist.pick(origin, look, { at(150, 7.5, "lejos") }) == nil, ("de lejos, más estrecho (%d°)"):format(C.ConeFar))
	check(AimAssist.pick(origin, look, { at(C.MaxDistance + 10, 0, "muy lejos") }) == nil, "demasiado lejos, nada")
	check(AimAssist.pick(origin, look, { at(60, 0, "fuera del alcance") }, nil, 40) == nil, "más lejos que el alcance del arma, nada")
	check(AimAssist.pick(origin, look, { at(20, 180, "detrás") }) == nil, "a la espalda, nada")
	check(AimAssist.coneFor(5) == C.ConeNear and AimAssist.coneFor(500) == C.ConeFar and AimAssist.coneFor(60) < C.ConeNear and AimAssist.coneFor(60) > C.ConeFar, "el cono se estrecha con la distancia")
end

print("▶ Al cuerpo, poco a poco")
do
	local torso = Vector3.new(0, 4, -20)
	local p = AimAssist.bodyPoint(torso)
	check(p.Y < torso.Y and p.Y > torso.Y - 1.5, "apunta al torso (algo por debajo de su centro), no a la cabeza")
	local target = at(20, 4, "T").Point
	local yaw, pitch = AimAssist.turn(look, target - origin, 1)
	check(yaw < 0 and math.abs(math.deg(yaw) + 4) < 0.01 and math.abs(pitch) < 1e-6, "el giro completo lleva la mira justo al objetivo (4° a la derecha)")
	local halfYaw = AimAssist.turn(look, target - origin, 0.5)
	check(math.abs(halfYaw - yaw / 2) < 1e-6, "con la mitad, la mitad del giro")
	local aimPull = AimAssist.pullFraction(true, 1 / 60)
	local hipPull = AimAssist.pullFraction(false, 1 / 60)
	check(aimPull > hipPull and aimPull < 0.2 and hipPull > 0, "suave: cada fotograma solo un poco (más apuntando que disparando desde la cadera)")
	check(C.Snap > aimPull * 3 and C.Snap < 1, "al pulsar Apuntar, un tirón corto (sin pegarse del todo)")
	local back = AimAssist.turn(Vector3.new(0, 0, 1), Vector3.new(0.05, 0, -1), 1)
	check(math.abs(back) <= math.pi + 1e-6, "gira siempre por el camino corto")
end

print("▶ Solo con el dedo o el mando")
check(AimAssist.enabled("Touch"), "con el dedo, sí")
check(AimAssist.enabled("Gamepad1"), "con el mando, sí")
check(not AimAssist.enabled("MouseMovement") and not AimAssist.enabled("MouseButton1") and not AimAssist.enabled("Keyboard"), "con ratón o teclado, nada")
check(not AimAssist.enabled(nil), "sin saberlo, nada")

print("▶ Solo objetivos válidos para las armas")
check(AimAssist.validTarget({ Alive = true, Player = true, CanFight = true }), "otro jugador con el que se puede pelear")
check(not AimAssist.validTarget({ Alive = true, Player = true, CanFight = true, SameTeam = true }), "uno de tu equipo, no")
check(not AimAssist.validTarget({ Alive = true, Player = true, CanFight = false }), "un bebé o alguien en una conversación, no")
check(not AimAssist.validTarget({ Alive = true, Player = true, CanFight = true, Seated = true }), "sentado (en un coche), no")
check(not AimAssist.validTarget({ Alive = true, Player = true, CanFight = true, Protected = true }), "en otro interior, no")
check(AimAssist.validTarget({ Alive = true, MissionEnemy = true }), "un enemigo de tu misión")
check(AimAssist.validTarget({ Alive = true, Rival = true }), "tu rival de entrenamiento")
check(not AimAssist.validTarget({ Alive = true, Npc = true }), "la gente de la calle, nunca")
check(not AimAssist.validTarget({ Alive = true, Npc = true, Officer = true }), "un agente de policía, nunca")
check(not AimAssist.validTarget({ Alive = false, MissionEnemy = true }), "ni los que ya han caído")
check(not AimAssist.validTarget({ Alive = true, IsSelf = true, Player = true, CanFight = true }), "ni tú")

print("▶ La cámara con el dedo")
do
	local d = Vector2.new(100, 40)
	local yaw, pitch = AimAssist.dragTurn(d, 0, false)
	check(yaw < 0 and pitch < 0, "arrastrar a la derecha y abajo gira a la derecha y mira abajo")
	local aimYaw = AimAssist.dragTurn(d, 1, false)
	check(math.abs(aimYaw) < math.abs(yaw) * 0.9, ("apuntando gira más despacio (x%.2f)"):format(C.AimSensitivity))
	local stickyYaw = AimAssist.dragTurn(d, 0, true)
	check(math.abs(stickyYaw) < math.abs(yaw), ("con la mira encima de alguien, un poco menos (fricción x%.2f)"):format(C.Friction))
	check(AimAssist.sensitivity(0, false) == 1, "sin apuntar y sin nadie delante, la de siempre")
end

print("▶ En el juego")
local wc = fs.readFile("src/client/Controllers/WeaponController.luau")
local function has(text: string): boolean
	return string.find(wc, text, 1, true) ~= nil
end
check(has("AimAssist.pick(") and has("canSee(") and has("AimAssist.validTarget(info)"), "WeaponController busca el objetivo válido con AimAssist.pick y la línea de visión")
check(has("assistOn()") and has("AimAssist.enabled(name)"), "la ayuda solo con el dedo o el mando")
check(has('Slot = "DispararIzq"') and has('Slot = "Disparar"') and has('Slot = "Apuntar"') and has('Slot = "Recargar"'), "botones del móvil: Disparar, el segundo Disparar, Apuntar y Recargar")
check(has("Drag = WeaponController.drag"), "arrastrar el dedo de Disparar gira la cámara")
check(has('holdTrigger("Izq"') and has('holdTrigger("Der"'), "cada Disparar con su dedo (soltar uno no corta el otro)")
check(has("Airborne = humanoid.FloorMaterial == Enum.Material.Air"), "en el aire se puede disparar (con algo más de dispersión)")
local ws = fs.readFile("src/server/Services/WeaponService.luau")
check(ws:find('Remote:FireServer', 1, true) == nil and ws:find("Weapons.ready(w, s.LastShot, now", 1, true) ~= nil and ws:find("mags(player)", 1, true) ~= nil, "el servidor sigue mandando: cadencia y munición se comprueban allí")
check(ws:find("AimAssist", 1, true) == nil, "la ayuda de apuntado no toca el servidor (solo mueve la cámara)")

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
