-- Prueba del combate aéreo y espacial (shared/AirCombat), con Lune (sin Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-aircombat.luau
--
-- Comprueba:
--   * Vuelo (ShipFlight): el motor marca la velocidad, el turbo gasta energía, se enfría y se recarga,
--     el freno frena y gira más cerrado, la autonivelación, inclinarse hace girar, en la atmósfera
--     subir cuesta velocidad y despacio se hunde, en el espacio no hay gravedad, chocar con el suelo o
--     una roca es «Crash», los límites hacen volver y la comprobación del servidor.
--   * Daño (Shields): el escudo para primero, los misiles atraviesan parte, se rompe, se regenera solo
--     tras el retraso, el casco a 0 es destruido y reset lo deja nuevo.
--   * Armas (ShipWeapons): cadencia y calor del láser, munición y recarga de misiles, el misil busca a
--     su blanco, el segmento del proyectil y el cono máximo del servidor.
--   * Fijación (Lock): cono y alcance, el más centrado, tarda LockTime, se suelta al salir, adelanto y
--     ayuda a apuntar.
--   * IA (EnemyAI): a quién ataca (quien le disparó, se queda con su blanco, el más cercano, nadie si
--     está lejos), enjambre en círculo, el caza persigue / esquiva / se aleja, la torreta no se mueve.
--   * Oleadas (Waves): las primeras, crecen y escalan, tope de enemigos, dificultad, la máquina de
--     oleadas (cuenta atrás → salen → superada → siguiente → fin).
--   * Arena: lejos de Valmar, puntos de control libres, modo por altura, choques y proyectiles.
--   * Mandos del móvil (HudLayout.Fly de la nave): ≥ 44 pt en el móvil del dueño y sin pisarse.
--   * Panel (AirCombatHud): textos, radar y flechas del borde.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, Vector2, CFrame, Color3, Enum = roblox.Vector3, roblox.Vector2, roblox.CFrame, roblox.Color3, roblox.Enum

local function load(path: string, extra: { [string]: any }?): any
	local env = setmetatable({ Vector3 = Vector3, Vector2 = Vector2, CFrame = CFrame, Color3 = Color3, Enum = Enum, UDim2 = roblox.UDim2, script = { Parent = extra or {} } }, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end

local ShipFlight = load("src/shared/AirCombat/ShipFlight.luau")
local Shields = load("src/shared/AirCombat/Shields.luau")
local ShipWeapons = load("src/shared/AirCombat/ShipWeapons.luau")
local Lock = load("src/shared/AirCombat/Lock.luau")
local EnemyAI = load("src/shared/AirCombat/EnemyAI.luau")
local Waves = load("src/shared/AirCombat/Waves.luau")
local Arena = load("src/shared/AirCombat/Arena.luau")
local FxBudget = load("src/shared/AirCombat/FxBudget.luau")

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

local function input(t: { [string]: any }?): any
	local i = { Pitch = 0, Yaw = 0, Roll = 0 }
	for k, v in t or {} do
		i[k] = v
	end
	return i
end
local function run(s: any, inp: any, seconds: number, env: any?): { string }
	local all = {}
	local dt = 1 / 60
	for _ = 1, math.floor(seconds / dt + 0.5) do
		for _, e in ShipFlight.advance(s, inp, dt, env) do
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
local spec = ShipFlight.Specs.Caza

---------------------------------------------------------------------
print("\n🚀 Vuelo (ShipFlight)")
---------------------------------------------------------------------
do
	local s = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	run(s, input({ SetThrottle = 1 }), 6, SPACE)
	check(near(s.Speed, spec.MaxSpeed, 2), ("a todo motor llega a la velocidad máxima (%.0f)"):format(s.Speed))
	run(s, input({ SetThrottle = 0 }), 6, SPACE)
	check(near(s.Speed, spec.MinSpeed, 2), ("con el motor al mínimo no se para: %.0f (mínimo %d)"):format(s.Speed, spec.MinSpeed))
	local look = s.Rot.LookVector
	check(look:Dot(Vector3.new(0, 0, -1)) > 0.999 and near(s.Sink, 0), "en el espacio sin tocar nada va recto (sin gravedad)")
	local y0 = s.Pos.Y
	run(s, input(), 3, SPACE)
	check(near(s.Pos.Y, y0, 0.5), "en el espacio no se hunde aunque vaya despacio")
end
do
	-- Turbo: gasta, se vacía, se enfría y se recarga
	local s = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	local ev = run(s, input({ SetThrottle = 1, Boost = true }), 1, SPACE)
	check(s.Boosting and s.Speed > spec.MaxSpeed, ("turbo: más rápido que a todo motor (%.0f)"):format(s.Speed))
	check(s.Boost < 0.7 and s.Boost > 0.5, ("el turbo gasta energía (%.2f tras 1 s)"):format(s.Boost))
	ev = run(s, input({ SetThrottle = 1, Boost = true }), 2, SPACE)
	check(has(ev, "BoostEmpty") and not s.Boosting and s.Boost <= 0, "gastado entero: se apaga solo (BoostEmpty)")
	run(s, input({ SetThrottle = 1, Boost = true }), spec.BoostCooldown * 0.5, SPACE)
	check(not s.Boosting and s.Boost == 0, "mientras se enfría no hay turbo aunque lo pidas")
	ev = run(s, input({ SetThrottle = 1 }), spec.BoostCooldown * 0.6, SPACE)
	check(has(ev, "BoostReady"), "al enfriarse avisa (BoostReady)")
	run(s, input({ SetThrottle = 1 }), spec.BoostRefill + 0.5, SPACE)
	check(near(s.Boost, 1), "y se recarga hasta arriba")
	-- Soltar antes de vaciarlo: sin enfriamiento
	local t = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	run(t, input({ Boost = true }), 0.5, SPACE)
	run(t, input(), 0.1, SPACE)
	check(ShipFlight.canBoost(t), "si lo sueltas antes de gastarlo, se puede volver a usar enseguida")
end
do
	-- Freno: más lento y gira más cerrado
	local function turnAngle(brake: boolean): number
		local s = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
		run(s, input({ Yaw = 1, Brake = brake, Roll = 0.001 }), 1, SPACE) -- (alabeo casi cero: sin la asistencia)
		local look = s.Rot.LookVector
		return math.deg(math.acos(math.clamp(look:Dot(Vector3.new(0, 0, -1)), -1, 1)))
	end
	local normal, tight = turnAngle(false), turnAngle(true)
	check(tight > normal * 1.3, ("frenando gira más cerrado (%.0f° contra %.0f° en 1 s)"):format(tight, normal))
	local s = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	run(s, input({ SetThrottle = 1, Brake = true }), 3, SPACE)
	check(near(s.Speed, spec.BrakeSpeed, 2) and s.Braking, ("el freno baja a %d (va a %.0f)"):format(spec.BrakeSpeed, s.Speed))
end
do
	-- Asistencia: al girar se inclina sola; al soltar vuelve a nivel
	local s = ShipFlight.new("Caza", CFrame.new(0, 2000, 0), "Atmos")
	run(s, input({ Yaw = 1 }), 1.5)
	local bank = math.deg(ShipFlight.bank(s))
	check(bank > 25, ("girando a la derecha se inclina sola a la derecha (%.0f°)"):format(bank))
	run(s, input(), 3)
	check(math.abs(math.deg(ShipFlight.bank(s))) < 5, ("al soltar se nivela sola (%.1f°)"):format(math.deg(ShipFlight.bank(s))))
	-- Alabeo a mano y viraje por inclinación
	local r = ShipFlight.new("Caza", CFrame.new(0, 2000, 0), "Atmos")
	r.Speed = 180
	run(r, input({ Roll = 1, SetThrottle = 0.8 }), 0.3)
	local banked = ShipFlight.bank(r)
	check(banked > 0.4, ("alabeo a la derecha: ala derecha abajo (%.0f°)"):format(math.deg(banked)))
	local before = r.Rot.LookVector
	run(r, input({ Roll = 0.001, SetThrottle = 0.8 }), 1)
	local after = r.Rot.LookVector
	check(before:Cross(after).Y < -0.05, "inclinada a la derecha, la nave gira a la derecha")
end
do
	-- Atmósfera: subir cuesta velocidad, despacio se hunde
	local up = ShipFlight.new("Caza", CFrame.new(0, 2000, 0) * CFrame.Angles(math.rad(60), 0, 0), "Atmos")
	local flat = ShipFlight.new("Caza", CFrame.new(0, 2000, 0), "Atmos")
	run(up, input({ SetThrottle = 0.5, Roll = 0.001 }), 2)
	run(flat, input({ SetThrottle = 0.5 }), 2)
	check(up.Speed < flat.Speed - 10, ("subir cuesta velocidad (%.0f subiendo, %.0f en llano)"):format(up.Speed, flat.Speed))
	local slow = ShipFlight.new("Caza", CFrame.new(0, 2000, 0), "Atmos")
	slow.Speed = spec.MinSpeed
	run(slow, input({ SetThrottle = 0, Brake = true }), 2)
	check(slow.Sink < -5 and slow.Warn == "Lento", ("muy despacio se hunde y avisa (%.1f studs/s)"):format(slow.Sink))
	local fast = ShipFlight.new("Caza", CFrame.new(0, 2000, 0), "Atmos")
	run(fast, input({ SetThrottle = 1 }), 3)
	check(fast.Sink > -1, "deprisa no se hunde")
end
do
	-- Choques y modos con la arena de verdad
	local env = { mode = Arena.modeAt, collide = Arena.collide, bounds = Arena.bounds }
	local s = ShipFlight.new("Caza", CFrame.new(Arena.Origin + Vector3.new(0, Arena.GroundY + 40, 0)) * CFrame.Angles(math.rad(-70), 0, 0), "Atmos")
	local ev = run(s, input({ SetThrottle = 1, Roll = 0.001 }), 3, env)
	check(has(ev, "Crash") and s.Crashed == "el suelo", "en picado contra la meseta: Crash («el suelo»)")
	local frozen = s.Pos
	run(s, input({ SetThrottle = 1 }), 1, env)
	check(s.Pos == frozen, "estrellada ya no se mueve (espera a reaparecer)")
	local rock = Arena.rocks()[1]
	local r = ShipFlight.new("Caza", CFrame.new(rock.Center + Vector3.new(0, 0, rock.Size.Z / 2 + 40)), "Atmos")
	ev = run(r, input({ SetThrottle = 1, Roll = 0.001 }), 2, env)
	check(has(ev, "Crash") and r.Crashed == "una roca", "de frente contra una aguja de roca: Crash («una roca»)")
	local climb = ShipFlight.new("Caza", CFrame.new(Arena.Origin + Vector3.new(0, Arena.SpaceY - 30, 0)) * CFrame.Angles(math.rad(80), 0, 0), "Atmos")
	ev = run(climb, input({ SetThrottle = 1, Roll = 0.001 }), 1, env)
	check(has(ev, "Space") and climb.Mode == "Space", "subiendo se pasa al espacio (evento Space)")
	local out = ShipFlight.new("Caza", CFrame.new(Arena.Origin + Vector3.new(Arena.Half + 50, 2400, 0)) * CFrame.Angles(0, math.rad(-90), 0), "Atmos")
	run(out, input({ SetThrottle = 0.6, Roll = 0.001 }), 0.2, env)
	local lookX = out.Rot.LookVector.X
	run(out, input({ SetThrottle = 0.6 }), 3, env)
	check(out.Warn == "Limite" or out.Rot.LookVector.X < lookX, "fuera del límite avisa y gira sola hacia dentro")
	check(out.Rot.LookVector.X < 0.2, ("…y acaba mirando hacia dentro (X %.2f)"):format(out.Rot.LookVector.X))
end
do
	-- Comprobación del servidor
	local a = Vector3.new(0, 0, 0)
	check(ShipFlight.plausible(spec, a, Vector3.new(0, 0, -spec.BoostSpeed / 30), 1 / 30), "a todo turbo, el salto de una vuelta es posible")
	check(not ShipFlight.plausible(spec, a, Vector3.new(0, 0, -500), 1 / 30), "500 studs en una vuelta no (teletransporte)")
	-- La orientación siempre ortonormal tras mucho tiempo girando
	local s = ShipFlight.new("Caza", CFrame.new(0, 5000, 0), "Space")
	run(s, input({ Pitch = 0.7, Yaw = 0.4, Roll = 0.9 }), 20, SPACE)
	local R = s.Rot
	check(near(R.LookVector.Magnitude, 1) and near(R.LookVector:Dot(R.UpVector), 0) and near(R.RightVector:Dot(R.UpVector), 0), "tras 20 s girando, la orientación sigue siendo buena")
	local f = ShipFlight.facing(Vector3.new(0, 0, -1))
	check(f.LookVector:Dot(Vector3.new(0, 0, -1)) > 0.999 and f.UpVector.Y > 0.999, "facing hacia -Z con el techo arriba (sin el CFrame.lookAt de Lune)")
end

---------------------------------------------------------------------
print("\n🛡️ Daño y escudos (Shields)")
---------------------------------------------------------------------
do
	local h = Shields.new("Caza")
	local r = Shields.apply(h, 20, 0, "Laser")
	check(r.Shield == 20 and r.Hull == 0 and h.Hull == 100 and h.Shield == 40, "el láser lo para el escudo entero")
	r = Shields.apply(h, 50, 1, "Laser")
	check(r.Broke and r.Shield == 40 and r.Hull == 10 and h.Hull == 90, "lo que sobra del escudo va al casco y el escudo se rompe")
	local m = Shields.new("Caza")
	r = Shields.apply(m, 40, 0, "Missile")
	check(near(r.Hull, 12) and near(r.Shield, 28), ("el misil atraviesa parte del escudo (%.0f al casco)"):format(r.Hull))
	check(Shields.regen(h, 2, 1) == 0, "recién golpeado no se regenera")
	local got = Shields.regen(h, 1 + h.Delay + 0.1, 1)
	check(near(got, Shields.Specs.Caza.Regen), ("pasado el retraso se regenera (%.0f por segundo)"):format(got))
	for _ = 1, 20 do
		Shields.regen(h, 100, 1)
	end
	check(h.Shield == h.MaxShield and h.Hull == 90, "el escudo se llena hasta su máximo; el casco no se cura solo")
	local d = Shields.new("Dron")
	r = Shields.apply(d, 999, 0, "Laser")
	check(r.Destroyed and Shields.destroyed(d) and d.Hull == 0, "casco a 0: destruido (y no baja de 0)")
	check(Shields.apply(d, 10, 1).Hull == 0, "ya destruido no recibe más")
	check(Shields.regen(d, 50, 1) == 0, "destruido no se regenera")
	Shields.reset(d)
	check(d.Hull == d.MaxHull and not Shields.destroyed(d), "reset: nuevo")
	local hard = Shields.new("Dron", 1.5)
	check(near(hard.MaxHull, Shields.Specs.Dron.Hull * 1.5), "el multiplicador de la oleada sube el casco")
	check(Shields.apply(Shields.new("Caza"), 0 / 0, 0).Hull == 0, "un daño roto (NaN) no hace nada")
end

---------------------------------------------------------------------
print("\n🔫 Armas (ShipWeapons)")
---------------------------------------------------------------------
do
	local L, M = ShipWeapons.Laser, ShipWeapons.Missile
	local g = ShipWeapons.newGun()
	check(ShipWeapons.tryLaser(g, 0) and not ShipWeapons.tryLaser(g, L.Cooldown * 0.5) and ShipWeapons.tryLaser(g, L.Cooldown + 0.001), "cadencia del láser")
	local h = ShipWeapons.newGun()
	local shots, t = 0, 0
	while not h.Overheated and shots < 200 do
		if ShipWeapons.tryLaser(h, t) then
			shots += 1
		end
		t += L.Cooldown
	end
	check(h.Overheated and shots > 10 and shots < 40, ("disparando sin parar se recalienta (%d disparos)"):format(shots))
	check(not ShipWeapons.tryLaser(h, t + 10), "recalentado no dispara")
	for _ = 1, 30 do
		ShipWeapons.tick(h, t, 0.1)
	end
	check(not h.Overheated and ShipWeapons.tryLaser(h, t + 20), "al enfriarse vuelve a disparar")
	local mg = ShipWeapons.newGun()
	local fired = 0
	local now = 0
	for _ = 1, 10 do
		if ShipWeapons.tryMissile(mg, now) then
			fired += 1
		end
		now += M.Cooldown
	end
	check(fired == M.Ammo and mg.Missiles == 0, ("%d misiles y se acaban"):format(fired))
	ShipWeapons.tick(mg, now, 0.1)
	local had = mg.Missiles
	ShipWeapons.tick(mg, now + M.Reload * 0.5, 0.1)
	local half = mg.Missiles
	ShipWeapons.tick(mg, now + M.Reload + 0.1, 0.1)
	check(half == had and mg.Missiles == had + 1, ("se recargan solos, uno cada %d s (%d → %d)"):format(M.Reload, had, mg.Missiles))
	-- El misil busca
	local missile = { Pos = Vector3.new(0, 0, 0), Dir = Vector3.new(0, 0, -1), Speed = 120 }
	local target = Vector3.new(300, 0, -300)
	local closest = math.huge
	for _ = 1, 300 do
		ShipWeapons.steerMissile(missile, target, 1 / 60)
		closest = math.min(closest, (missile.Pos - target).Magnitude)
	end
	check(closest < M.HitRadius + 6, ("el misil gira y llega a un blanco a 45° (pasa a %.1f studs)"):format(closest))
	check(missile.Speed <= M.Speed and missile.Speed > 200, "acelera hasta su velocidad")
	-- Proyectiles
	check(ShipWeapons.segmentHits(Vector3.new(0, 0, 0), Vector3.new(0, 0, -100), Vector3.new(1, 0, -50), 2), "el proyectil rápido da a lo que cruza entre dos vueltas")
	check(not ShipWeapons.segmentHits(Vector3.new(0, 0, 0), Vector3.new(0, 0, -100), Vector3.new(5, 0, -50), 2), "y no a lo que pasa lejos")
	check(ShipWeapons.aimAllowed(Vector3.new(0, 0, -1), Vector3.new(0.3, 0, -1).Unit), "el servidor deja apuntar un poco fuera del morro")
	check(not ShipWeapons.aimAllowed(Vector3.new(0, 0, -1), Vector3.new(0, 0, 1)), "pero no disparar hacia atrás")
	check(not ShipWeapons.aimAllowed(Vector3.new(0, 0, -1), Vector3.new(0, 0, -50)), "ni con una dirección rara (no unitaria)")
end

---------------------------------------------------------------------
print("\n🎯 Fijación y ayuda a apuntar (Lock)")
---------------------------------------------------------------------
do
	local C = Lock.Config
	local origin, look = Vector3.new(0, 0, 0), Vector3.new(0, 0, -1)
	local list = {
		{ Id = "lejos", Pos = Vector3.new(0, 0, -(C.Range + 200)) },
		{ Id = "fuera", Pos = Vector3.new(300, 0, -300) },
		{ Id = "centrado", Pos = Vector3.new(5, 0, -400) },
		{ Id = "ladeado", Pos = Vector3.new(60, 0, -400) },
	}
	local best = Lock.best(origin, look, list)
	check(best and best.Id == "centrado", "elige el más centrado dentro del cono y del alcance")
	local s = Lock.new()
	local ev = Lock.update(s, origin, look, list, 0.1)
	check(ev == "Start" and s.Target == "centrado" and not s.Locked, "empieza a fijar")
	local t = 0.1
	local locked = false
	while t < 3 and not locked do
		locked = Lock.update(s, origin, look, list, 0.05) == "Locked"
		t += 0.05
	end
	check(locked and near(t, C.LockTime + 0.1, 0.11), ("fija tras %.2f s (LockTime %.2f)"):format(t, C.LockTime))
	-- Se mueve un poco: sigue (Hold); sale del todo: se pierde
	list[3].Pos = Vector3.new(110, 0, -400)
	check(Lock.update(s, origin, look, list, 0.05) == nil and s.Locked, "un poco fuera del cono sigue fijado (margen)")
	list[3].Pos = Vector3.new(400, 0, -100)
	list[4].Pos = Vector3.new(400, 0, -100)
	ev = Lock.update(s, origin, look, list, 0.05)
	check(ev == "Lost" and not s.Locked and s.Target == nil, "fuera del todo: se pierde")
	-- Cambiar de blanco empieza de cero
	local s2 = Lock.new()
	local two = { { Id = "a", Pos = Vector3.new(0, 0, -300) }, { Id = "b", Pos = Vector3.new(20, 0, -300) } }
	Lock.update(s2, origin, look, two, 0.4)
	Lock.update(s2, origin, look, two, 0.4)
	table.remove(two, 1)
	Lock.update(s2, origin, look, two, 0.1)
	check(s2.Target == "b" and s2.Progress == 0, "si el blanco desaparece, el siguiente empieza de cero")
	-- Adelanto y ayuda
	local lead = Lock.lead(origin, 1000, Vector3.new(0, 0, -500), Vector3.new(100, 0, 0))
	check(lead.X > 45 and lead.X < 56, ("adelanto: apunta a donde estará (%.0f studs a un lado)"):format(lead.X))
	local dir, id = Lock.assist(origin, look, { { Id = "x", Pos = Vector3.new(15, 0, -500), Vel = Vector3.zero } }, math.rad(5), 1000)
	check(id == "x" and dir.X > 0.02, "la ayuda corrige el disparo hacia el enemigo del cono pequeño")
	local dir2, id2 = Lock.assist(origin, look, { { Id = "x", Pos = Vector3.new(200, 0, -500) } }, math.rad(5), 1000)
	check(id2 == nil and near(dir2.X, 0), "y no hace nada si está lejos del centro")
	check(C.AssistConeTouch > C.AssistCone, "en el móvil el cono de ayuda es más ancho")
end

---------------------------------------------------------------------
print("\n🤖 IA de los enemigos (EnemyAI)")
---------------------------------------------------------------------
do
	local e = EnemyAI.new("d1", "Dron", Vector3.new(0, 0, 0))
	local pilots = {
		{ Id = "A", Pos = Vector3.new(0, 0, -300) },
		{ Id = "B", Pos = Vector3.new(0, 0, -900) },
	}
	check(EnemyAI.pickTarget(e, pilots, 0) == "A", "elige al más cercano")
	e.Target = "B"
	pilots[1].Pos = Vector3.new(0, 0, -600)
	check(EnemyAI.pickTarget(e, pilots, 0) == "B" or false, "se queda con el que tenía si no hay otro MUCHO más cerca")
	pilots[1].Pos = Vector3.new(0, 0, -100)
	check(EnemyAI.pickTarget(e, pilots, 0) == "A", "…pero cambia si otro está a menos de la mitad")
	EnemyAI.hit(e, "B", 10)
	check(EnemyAI.pickTarget(e, pilots, 11) == "B", "persigue a quien le acaba de disparar")
	check(EnemyAI.pickTarget(e, pilots, 30) == "A", "y se le olvida al rato")
	local far = EnemyAI.new("d2", "Dron", Vector3.new(0, 0, 0))
	check(EnemyAI.pickTarget(far, { { Id = "Z", Pos = Vector3.new(0, 0, -5000) } }, 0) == nil, "nadie si está fuera del radio de alerta")
	check(EnemyAI.pickTarget(far, { { Id = "Z", Pos = Vector3.new(0, 0, -100), Alive = false } }, 0) == nil, "a uno derribado (esperando a reaparecer) no le ataca")
	-- Enjambre: se acerca y luego da vueltas a su alrededor sin chocar
	local target = { Id = "A", Pos = Vector3.new(0, 0, 0), Vel = Vector3.zero, Look = Vector3.new(0, 0, -1) }
	local swarm = {}
	for i = 1, 4 do
		table.insert(swarm, EnemyAI.new("s" .. i, "Dron", Vector3.new(i * 30, 0, 900), Vector3.new(0, 0, -1), nil, i * 1.7))
	end
	local minD, fireCount = math.huge, 0
	local t = 0
	for _ = 1, 600 do
		t += 1 / 30
		for _, d in swarm do
			local dir, speed, fireNow = EnemyAI.think(d, target, t, swarm)
			if fireNow then
				fireCount += 1
				EnemyAI.fired(d, t)
			end
			EnemyAI.steer(d, dir, speed, 1 / 30)
		end
		if t > 10 then
			for i = 1, #swarm do
				for j = i + 1, #swarm do
					minD = math.min(minD, (swarm[i].Pos - swarm[j].Pos).Magnitude)
				end
			end
		end
	end
	local avg = 0
	for _, d in swarm do
		avg += (d.Pos - target.Pos).Magnitude / #swarm
	end
	local orbit = EnemyAI.Kinds.Dron.Orbit
	check(avg < orbit * 2.2 and avg > orbit * 0.3, ("el enjambre te rodea (a %.0f studs de media; círculo %d)"):format(avg, orbit))
	check(swarm[1].Mode == "Strafe" or swarm[2].Mode == "Strafe", "ya cerca, ametralla en círculo (Strafe)")
	check(fireCount > 4, ("dispara al pasar de cara (%d disparos en 20 s)"):format(fireCount))
	check(minD > 8, ("no se chocan entre ellos (mínimo %.0f studs)"):format(minD))
	-- Caza enemigo
	local f = EnemyAI.new("f1", "Caza", Vector3.new(0, 0, 600), Vector3.new(0, 0, -1))
	local _, _, _ = EnemyAI.think(f, target, 0)
	check(f.Mode == "Pursue", "el caza persigue")
	EnemyAI.hit(f, "A", 5)
	EnemyAI.think(f, target, 5.1)
	check(f.Mode == "Evade", "si le das, rompe y esquiva")
	local dirE = EnemyAI.think(f, target, 5.2)
	local away = (f.Pos - target.Pos).Unit
	check(dirE:Dot(-away) < 0.6, "esquivando no va directo hacia ti")
	local tail = EnemyAI.new("f2", "Caza", Vector3.new(0, 0, -150), Vector3.new(0, 0, -1))
	EnemyAI.think(tail, { Id = "A", Pos = Vector3.zero, Look = Vector3.new(0, 0, -1) }, 1)
	check(tail.Mode == "Evade", "si te le pones detrás, esquiva")
	local close = EnemyAI.new("f3", "Caza", Vector3.new(0, 0, -50), Vector3.new(0, 0, 1))
	EnemyAI.think(close, { Id = "A", Pos = Vector3.zero, Look = Vector3.new(1, 0, 0) }, 1)
	check(close.Mode == "Extend", "encima de ti, se aleja para volver a entrar")
	-- Torreta
	local tur = EnemyAI.new("t1", "Torreta", Vector3.new(0, 0, 0), Vector3.new(1, 0, 0))
	local start = tur.Pos
	local shots = 0
	for i = 1, 120 do
		local dir, speed, fireNow = EnemyAI.think(tur, { Id = "A", Pos = Vector3.new(0, 0, -400), Vel = Vector3.zero }, i / 30)
		if fireNow then
			shots += 1
			EnemyAI.fired(tur, i / 30)
		end
		EnemyAI.steer(tur, dir, speed, 1 / 30)
	end
	check(tur.Pos == start and tur.Look:Dot(Vector3.new(0, 0, -1)) > 0.99, "la torreta no se mueve: gira hacia ti")
	check(shots >= 2, ("y dispara cuando te tiene a tiro (%d)"):format(shots))
	local strong = EnemyAI.new("x", "Dron", Vector3.zero, nil, { Damage = 2, Fire = 2 })
	check(EnemyAI.damage(strong) == EnemyAI.Kinds.Dron.Damage * 2, "los multiplicadores de la oleada suben el daño")
	EnemyAI.fired(strong, 0)
	check(near(strong.NextFire, EnemyAI.Kinds.Dron.FireCooldown / 2), "…y la cadencia")
end

---------------------------------------------------------------------
print("\n🌊 Oleadas (Waves)")
---------------------------------------------------------------------
do
	check(Waves.count(1, "Atmos") == 3 and Waves.compose(1, "Atmos")[1].Kind == "Dron", "la primera: 3 drones")
	local w3 = Waves.compose(3, "Atmos")
	local kinds = {}
	for _, g in w3 do
		kinds[g.Kind] = g.Count
	end
	check(kinds.Caza == 1 and kinds.Torreta == 2, "la tercera ya trae un caza y torretas")
	local grows = true
	for n = 2, 12 do
		if Waves.count(n, "Space") < Waves.count(n - 1, "Space") then
			grows = false
		end
	end
	check(grows, "cada oleada trae los mismos o más enemigos")
	local capped = true
	for n = 1, 40 do
		for _, d in { "Facil", "Normal", "Dificil" } do
			if Waves.count(n, "Atmos", d) > Waves.MaxAlive then
				capped = false
			end
		end
	end
	check(capped, ("nunca más de %d a la vez (móvil)"):format(Waves.MaxAlive))
	local s1, s5, s30 = Waves.scale(1), Waves.scale(5), Waves.scale(30)
	check(s1.Hull == 1 and s5.Hull > s1.Hull and s5.Damage > s1.Damage, "la dificultad sube con las oleadas")
	check(s30.Hull <= 2.2 and s30.Speed <= 1.25, "con tope (no se vuelven imposibles)")
	check(Waves.scale(3, "Dificil").Damage > Waves.scale(3, "Normal").Damage and Waves.scale(3, "Facil").Damage < Waves.scale(3, "Normal").Damage, "Fácil / Normal / Difícil")
	check(Waves.count(5, "Atmos", "Facil") < Waves.count(5, "Atmos", "Dificil"), "en Difícil salen más")
	-- Máquina
	local sp = Waves.new({ Section = "Space", FirstDelay = 2, Intermission = 3, MaxWaves = 2 })
	check(Waves.step(sp, 1, 0) == nil and string.find(Waves.objective(sp, 0), "Prepárate", 1, true) ~= nil, "cuenta atrás antes de la primera")
	local ev = Waves.step(sp, 1.1, 0)
	check(ev and ev.Type == "Spawn" and ev.Wave == 1 and ev.Groups and #ev.Groups > 0 and sp.Phase == "Fighting", "salen los de la oleada 1")
	check(Waves.step(sp, 5, 4) == nil and string.find(Waves.objective(sp, 4), "derriba 4", 1, true) ~= nil, "mientras quedan, se pelea (objetivo: derriba 4)")
	ev = Waves.step(sp, 0.1, 0)
	check(ev and ev.Type == "Cleared" and sp.Phase == "Intermission", "sin enemigos: oleada superada")
	Waves.setSection(sp, "Atmos")
	ev = Waves.step(sp, 3.1, 0)
	check(ev and ev.Type == "Spawn" and ev.Wave == 2 and sp.Section == "Atmos", "la siguiente sale en la sección donde estás")
	ev = Waves.step(sp, 0.1, 0)
	check(ev and ev.Type == "Done" and Waves.step(sp, 10, 0) == nil, "con MaxWaves, al limpiar la última: Done")
	local ring = Waves.ring(6, Vector3.zero, 500, 1)
	local okRing = #ring == 6
	for _, p in ring do
		if math.abs(Vector2.new(p.X, p.Z).Magnitude - 500) > 1 then
			okRing = false
		end
	end
	check(okRing, "los puntos de salida forman un anillo")
end

---------------------------------------------------------------------
print("\n🏜️ Arena (lejos de Valmar)")
---------------------------------------------------------------------
do
	local O = Arena.Origin
	check(math.abs(O.X) - Arena.SlabHalf > 15000 and math.abs(O.Z) - Arena.SlabHalf > 15000, "a más de 15 000 studs del borde del mapa de Valmar (±5600)")
	for _, section in { "Atmos", "Space" } do
		local cp = Arena.checkpoint(section)
		check(Arena.collide(cp.Position, 12) == nil and Arena.modeAt(cp.Position) == section and Arena.bounds(cp.Position) == nil, ("punto de control de %s libre y dentro"):format(section))
		-- 6 s hacia delante desde el punto de control sin chocar
		local env = { mode = Arena.modeAt, collide = Arena.collide, bounds = Arena.bounds }
		local s = ShipFlight.new("Caza", cp, section)
		local ev = run(s, input({ SetThrottle = 0.65 }), 6, env)
		check(not has(ev, "Crash"), ("al salir del punto de control de %s no hay nada en medio"):format(section))
		check(Arena.collide(Arena.center(section), 30) == nil, ("el centro de %s (donde salen los enemigos) está libre"):format(section))
	end
	check(#Arena.rocks() >= 15 and #Arena.asteroids() >= 25, ("rocas (%d) y asteroides (%d)"):format(#Arena.rocks(), #Arena.asteroids()))
	check(Arena.rocks() == Arena.rocks() and Arena.asteroids()[1].Radius == Arena.asteroids()[1].Radius, "siempre las mismas (cliente y servidor iguales)")
	local a = Arena.asteroids()[1]
	check(Arena.collide(a.Center + Vector3.new(a.Radius + 2, 0, 0), 3) == "un asteroide", "chocar con un asteroide")
	check(Arena.segmentBlocked(a.Center + Vector3.new(0, 0, a.Radius + 50), a.Center - Vector3.new(0, 0, a.Radius + 50)), "un disparo no atraviesa un asteroide")
	local spots = Arena.turretSpots("Atmos")
	check(#spots >= 4 and #Arena.turretSpots("Space") >= 4, "sitios para torretas en las dos secciones")
	check(Arena.contains(Arena.checkpoint("Atmos").Position) and not Arena.contains(Vector3.new(0, 50, 0), 400), "Valmar no es la arena")
end

---------------------------------------------------------------------
print("\n📱 Mandos del móvil y panel")
---------------------------------------------------------------------
do
	local L = require("./lib/ModuleLoader")
	local HudLayout = L.load("src/client/UI/HudLayout")
	local ids = { "Fuego", "Misil", "Turbo", "FrenoNave", "SalirNave" }
	for _, size in { { 932, 430 }, { 844, 390 }, { 640, 360 }, { 1180, 820 } } do
		local layout = HudLayout.compute(Vector2.new(size[1], size[2]), { Touch = true })
		local rects = {}
		local small = {}
		for _, id in ids do
			local p = layout.FlySlots[id]
			if not p then
				table.insert(small, id .. " (sin hueco)")
				continue
			end
			local r = HudLayout.rect(p, layout.Canvas)
			rects[id] = r
			-- (44 pt en los móviles normales; en uno diminuto de 640x360, que todo escala, al menos 32)
			local need = if size[1] == 640 then 32 else 44
			if math.min(r.W, r.H) * layout.Scale < need then
				table.insert(small, ("%s %d pt"):format(id, math.floor(math.min(r.W, r.H) * layout.Scale)))
			end
		end
		check(#small == 0, ("%dx%d: botones de la nave grandes (≥ 44 pt)%s"):format(size[1], size[2], if #small > 0 then " (" .. table.concat(small, ", ") .. ")" else ""))
		local clash = {}
		for i = 1, #ids do
			for j = i + 1, #ids do
				local a, b = rects[ids[i]], rects[ids[j]]
				if a and b and HudLayout.overlaps(a, b) then
					table.insert(clash, ids[i] .. "/" .. ids[j])
				end
			end
			for _, item in { "Hotbar", "Mission", "Minimap", "Flight" } do
				local p = layout.Items[item]
				local r = rects[ids[i]]
				if p and r and HudLayout.overlaps(r, HudLayout.rect(p, layout.Canvas)) then
					table.insert(clash, ids[i] .. "/" .. item)
				end
			end
		end
		check(#clash == 0, ("%dx%d: no se pisan entre ellos ni con la barra, la misión, el minimapa o el panel%s"):format(size[1], size[2], if #clash > 0 then " (" .. table.concat(clash, ", ") .. ")" else ""))
		local fire = rects.Fuego
		check(fire and fire.W >= 140 and layout.Canvas.X - (fire.X + fire.W) <= 30, ("%dx%d: FUEGO grande y pegado a la esquina"):format(size[1], size[2]))
	end
	-- Panel (textos puros), radar y flechas
	-- (solo las cuentas del panel: Theme sin crear nada)
	L.mock("src/client/UI/Theme", { Colors = {}, Hud = {}, create = function() end })
	local Hud = L.load("src/client/UI/AirCombatHud")
	local t = Hud.texts({ Speed = 212.4, Boost = 0.5, BoostReady = true, Shield = 30.4, MaxShield = 60, Hull = 80, MaxHull = 100, Missiles = 3, MaxMissiles = 6, Overheated = false, Wave = 2, Score = 400, Objective = "Oleada 2 · derriba 3 enemigos", Warn = nil, Mode = "Space" })
	check(t.Speed == "212" and t.Boost == "50%" and t.Shield == "30" and t.Hull == "80" and t.Missiles == "3/6", "panel: velocidad, turbo, escudo, casco y misiles")
	check(string.find(t.Objective, "derriba 3", 1, true) ~= nil and string.find(t.Objective, "400 pts", 1, true) ~= nil, "objetivo y puntos")
	local hot = Hud.texts({ Speed = 0, Boost = 0, BoostReady = false, Shield = 0, MaxShield = 60, Hull = 0, MaxHull = 100, Missiles = 0, MaxMissiles = 6, Overheated = true, Wave = 0, Score = 0, Objective = "", Warn = "Limite", Mode = "Atmos" })
	check(hot.Boost == "ENFRIANDO" and string.find(hot.Warning, "RECALENTADOS", 1, true) ~= nil, "turbo enfriándose y cañones recalentados")
	local ship = CFrame.new(0, 0, 0)
	local ahead = Hud.radarPoint(ship, Vector3.new(0, 0, -700))
	local right = Hud.radarPoint(ship, Vector3.new(700, 0, 0))
	local farAway = Hud.radarPoint(ship, Vector3.new(0, 0, 99999))
	check(ahead.Y < -0.4 and near(ahead.X, 0), "radar: delante = arriba")
	check(right.X > 0.4, "radar: a la derecha = derecha")
	check(near(farAway.Magnitude, 1) and farAway.Y > 0, "radar: muy lejos detrás se queda en el borde de abajo")
	local vp = Vector2.new(1000, 600)
	local p, angle = Hud.edgeArrow(Vector2.new(2000, 300), vp, false)
	check(near(p.X, 1000 - 48, 1) and near(angle, 90, 1), "flecha: un enemigo a la derecha, flecha en el borde derecho apuntando a la derecha")
	local pb = Hud.edgeArrow(Vector2.new(500, 100), vp, true)
	check(pb.Y > 300, "flecha: detrás de la cámara, la flecha va abajo")
	check(Hud.onScreen(Vector2.new(500, 300), vp, false) and not Hud.onScreen(Vector2.new(500, 300), vp, true), "dentro de la pantalla solo si está delante")
end

---------------------------------------------------------------------
print("\n🖥️ Servidor (AirCombatService): oleadas, disparos, daño, derribos y reaparecer")
---------------------------------------------------------------------
do
	local L = require("./lib/ModuleLoader")
	L.services.Players = { PlayerRemoving = { Connect = function() end } }
	local Service = L.load("src/server/Services/AirCombatService")
	local AirArena = L.load("src/server/World/AirArena")
	local ok, arena = pcall(AirArena.build)
	check(ok and arena and #arena:GetChildren() > 50, "la arena se construye (meseta, rocas, anillos, asteroides, balizas)" .. (if ok then "" else ": " .. tostring(arena)))
	local cp = Arena.checkpoint("Atmos")
	local okShip, ship = pcall(AirArena.ship, cp)
	check(okShip and ship.PrimaryPart and ship:FindFirstChild("ShipSeat"), "la nave tiene Root y asiento" .. (if okShip then "" else ": " .. tostring(ship)))
	for _, kind in { "Dron", "Caza", "Torreta" } do
		local okE, m = pcall(AirArena.enemy, kind, CFrame.new(0, 0, 0))
		check(okE and m.PrimaryPart and m.PrimaryPart.Anchored, kind .. ": modelo con Root anclado")
	end
	if okShip then
		ship.Parent = L.workspace
		local folder = roblox.Instance.new("Model")
		folder.Parent = L.workspace
		local attrs = {}
		local player = { UserId = 77, Parent = true, SetAttribute = function(_, k, v)
			attrs[k] = v
		end }
		-- (las piezas de Lune no tienen Position: un Root de mentira con su CFrame)
		local fakeRoot = setmetatable({ CFrame = cp, AssemblyLinearVelocity = Vector3.zero, Parent = true }, {
			__index = function(t, k)
				if k == "Position" then
					return rawget(t, "CFrame").Position
				end
				return nil
			end,
		})
		local s = {
			Player = player, Ship = ship, Root = fakeRoot, Seat = ship:FindFirstChild("ShipSeat"),
			Humanoid = { Parent = true, Health = 100 }, Section = "Atmos", Difficulty = "Normal",
			Hull = Shields.new("Caza"), Gun = ShipWeapons.newGun(),
			Spawner = Waves.new({ Section = "Atmos", FirstDelay = 0.01 }), Enemies = {}, Folder = folder,
			Bolts = {}, Missiles = {}, LastPos = cp.Position, LastGood = cp, LastAt = 0, Down = false,
			DownUntil = 0, Score = 0, Kills = 0, NextId = 0, StateAt = 0, Exiting = false, Conns = {},
		}
		Service._sessions[player] = s
		local stepOk, err = pcall(Service._step, s, 1 / 30)
		check(stepOk, "una vuelta del combate sin errores" .. (if stepOk then "" else ": " .. tostring(err)))
		local n = 0
		for _ in s.Enemies do
			n += 1
		end
		check(n == 3 and #folder:GetChildren() == 3, ("sale la oleada 1 (%d drones)"):format(n))
		-- Disparar a un enemigo hasta derribarlo
		local id, rec = next(s.Enemies)
		rec.AI.Pos = cp.Position + Vector3.new(0, 0, -300)
		rec.AI.Look = Vector3.new(0, 0, 1)
		rec.AI.Mult.Speed = 0
		rec.AI.Speed = 0
		rec.AI.NextFire = math.huge
		for _, other in s.Enemies do
			other.AI.NextFire = math.huge
		end
		local dir = (rec.AI.Pos - cp.Position).Unit
		Service._fire(s, Vector3.new(0, 0, 1)) -- (hacia atrás: no vale)
		check(#s.Bolts == 0, "el servidor no deja disparar hacia atrás")
		local hp0 = rec.Hp.Hull
		for _ = 1, 30 do
			s.Gun.NextLaser = 0
			s.Gun.Heat = 0
			s.Gun.Overheated = false
			Service._fire(s, dir)
			for _ = 1, 3 do
				rec.AI.Pos = cp.Position + Vector3.new(0, 0, -300)
				pcall(Service._step, s, 1 / 30)
			end
			if not s.Enemies[id] then
				break
			end
		end
		check(s.Enemies[id] == nil and s.Kills == 1 and s.Score > 0, ("los láseres lo derriban (casco %.0f → estalla, %d puntos)"):format(hp0, s.Score))
		-- Misil: sin blanco válido no sale; con el blanco delante sí
		local id2, rec2 = next(s.Enemies)
		Service._missile(s, "no-existe")
		check(#s.Missiles == 0, "misil a un blanco que no existe: nada")
		rec2.AI.Pos = cp.Position + Vector3.new(0, 0, 300)
		Service._missile(s, id2)
		check(#s.Missiles == 0, "misil a un blanco que está detrás: nada (no lo tenía fijado)")
		rec2.AI.Pos = cp.Position + Vector3.new(10, 0, -400)
		Service._missile(s, id2)
		check(#s.Missiles == 1 and s.Gun.Missiles == ShipWeapons.Missile.Ammo - 1, "misil a un blanco delante: sale y gasta uno")
		for _ = 1, 120 do
			rec2.AI.Pos = cp.Position + Vector3.new(10, 0, -400)
			pcall(Service._step, s, 1 / 30)
			if #s.Missiles == 0 then
				break
			end
		end
		check(#s.Missiles == 0 and (s.Enemies[id2] == nil or s.Enemies[id2].Hp.Hull < s.Enemies[id2].Hp.MaxHull), "el misil busca y da en el blanco")
		-- Disparos enemigos: el escudo para, luego el casco, y a 0 derribado
		s.Bolts = {}
		for _ = 1, 40 do
			table.insert(s.Bolts, { Pos = cp.Position + Vector3.new(0, 0, -30), Dir = Vector3.new(0, 0, 1), Speed = 500, Life = 1, Damage = 10, Enemy = true, Radius = 1.6 })
			pcall(Service._step, s, 1 / 30)
			if s.Down then
				break
			end
		end
		check(s.Down and s.Hull.Hull == 0, "los disparos enemigos bajan el escudo y el casco: a 0, derribado")
		s.DownUntil = 0
		pcall(Service._step, s, 1 / 30)
		check(not s.Down and s.Hull.Hull == s.Hull.MaxHull and s.Hull.Shield == s.Hull.MaxShield and (s.Root.Position - cp.Position).Magnitude < 1, "reaparece en el punto de control con todo lleno")
		-- Validación: un salto imposible vuelve atrás; meterse en una roca es estrellarse
		s.Root.CFrame = cp + Vector3.new(0, 0, -900)
		pcall(Service._step, s, 1 / 30)
		check((s.Root.Position - cp.Position).Magnitude < 1, "un salto imposible (teletransporte) vuelve al último sitio bueno")
		local rock = Arena.rocks()[1]
		s.LastPos = rock.Center
		s.Root.CFrame = CFrame.new(rock.Center)
		pcall(Service._step, s, 1 / 30)
		check(s.Down, "metido en una roca: estrellado")
		Service._sessions[player] = nil
	end
end

---------------------------------------------------------------------
print("\n✨ Efectos (FxBudget)")
---------------------------------------------------------------------
do
	local low, mid, high = FxBudget.get("Low"), FxBudget.get("Medium"), FxBudget.get("High")
	check(low.Tracers < mid.Tracers and mid.Tracers < high.Tracers and low.Sparks < high.Sparks, "menos efectos en Bajo que en Alto")
	check(not low.Lights and high.Lights, "en Bajo sin luces de verdad")
	check(low.WreckMax < high.WreckMax and low.Wrecks >= 1 and low.WreckFire < high.WreckFire, "restos en llamas en todos los niveles, menos en Bajo")
	check(FxBudget.sparks("Low", 1) <= low.Sparks and FxBudget.sparks("High", 0.1) >= 4, "chispas según el tamaño del estallido, con mínimo")
	check(FxBudget.get("Nope") == mid, "un nivel desconocido usa Medio")
end

print("")
if failures > 0 then
	print(("❌ test-aircombat: %d fallos"):format(failures))
	process.exit(1)
end
print("✅ test-aircombat: todo correcto")
