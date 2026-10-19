-- Prueba de los aviones que se pilotan, con Lune (sin Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-flight.luau                 (solo el modelo de vuelo)
--   rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl
--   lune run scripts/test-flight.luau /tmp/x.rbxl     (y además los modelos de los aviones del mapa)
--
-- Comprueba:
--   * El modelo de vuelo (Shared/Flight): la sustentación crece con la velocidad al cuadrado, la
--     resistencia también (más con tren y flaps), por debajo de Vr no despega, distancia de despegue
--     (la avioneta cabe en la pista corta de las Gaviotas; el avión de línea necesita la de Valmar),
--     pérdida (aviso, el morro baja solo y se recupera), los flaps bajan la pérdida, subir gasta
--     velocidad, inclinarse hace girar, aterrizajes suave / duro / accidente (sin tren, con un ala, al
--     agua, de morro), una aproximación de verdad acaba en aterrizaje suave, chocar en vuelo es
--     accidente y rodando despacio solo para, frenos, límites del mapa y techo de vuelo.
--   * Los modelos (con el mapa): piezas dentro del presupuesto, alas simétricas, luces roja a la
--     izquierda y verde a la derecha, el tren toca el suelo, largo y envergadura como Airport.Kinds,
--     asientos, el del piloto y el punto para subir en los que se pilotan (Atomic), los de los vuelos
--     siempre cargados (Persistent) y los aparcados lejos de por donde ruedan los aviones de los vuelos.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, Vector2, CFrame, Color3, Enum = roblox.Vector3, roblox.Vector2, roblox.CFrame, roblox.Color3, roblox.Enum

local function load(path: string): any
	local env = setmetatable({ Vector3 = Vector3, Vector2 = Vector2, CFrame = CFrame, Color3 = Color3, Enum = Enum, script = { Parent = {} } }, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end
local Flight = load("src/shared/Flight.luau")
local Airport = load("src/shared/Airport.luau")

local failures = 0
local function check(ok: boolean, what: string)
	print((if ok then "  ✅ " else "  ❌ ") .. what)
	if not ok then
		failures += 1
	end
end

local G = Airport.GROUND
local function flat(surface: string?): any
	return {
		ground = function(_p)
			return G, surface or "Pista"
		end,
	}
end
local function input(t: { [string]: any }?): any
	local i = { Pitch = 0, Roll = 0, Yaw = 0, Throttle = 0, Brake = false }
	for k, v in t or {} do
		i[k] = v
	end
	return i
end
-- Avión en el aire a esta velocidad y altura, nivelado, rumbo norte
local function airborne(kind: string, speed: number, y: number, x: number?, z: number?): any
	local s = Flight.new(kind, CFrame.new(x or 0, y, z or 0))
	s.OnGround = false
	s.Speed = speed
	s.Throttle = 0.6
	s.Gear = Flight.Specs[kind].FixedGear
	return s
end
local function run(s: any, inp: any, seconds: number, env: any?): { string }
	local all = {}
	local t = 0
	while t < seconds - 1e-6 and not s.Crashed do
		for _, e in Flight.advance(s, inp, 1 / 30, env or flat()) do
			table.insert(all, e)
		end
		t += 1 / 30
	end
	return all
end
local function has(list: { string }, what: string): boolean
	return table.find(list, what) ~= nil
end

---------------------------------------------------------------------
print("▶ Sustentación y resistencia")
for kind, spec in Flight.Specs do
	local l1, l2 = Flight.lift(spec, 50, 0), Flight.lift(spec, 100, 0)
	check(math.abs(l2 / l1 - 4) < 1e-6 and math.abs(Flight.lift(spec, spec.Vstall, 0) - 1) < 1e-6, kind .. ": la sustentación crece con la velocidad al cuadrado (y sostiene justo en Vstall)")
	check(Flight.stallSpeed(spec, spec.Flaps) < spec.Vstall * 0.9 and spec.Vr > spec.Vstall, kind .. ": con flaps la pérdida llega antes de Vstall; Vr es mayor que Vstall")
	local d0, dGear, dFlaps = Flight.drag(spec, 100, false, 0), Flight.drag(spec, 100, true, 0), Flight.drag(spec, 100, false, spec.Flaps)
	check(math.abs(Flight.drag(spec, 200, false, 0) / d0 - 4) < 1e-6 and (spec.FixedGear or dGear > d0) and dFlaps > d0, kind .. ": la resistencia crece con la velocidad al cuadrado; el tren y los flaps frenan")
	check(math.abs(Flight.drag(spec, spec.Vmax, false, 0) - spec.Accel) < 1e-6, kind .. ": a todo gas en llano no pasa de Vmax")
end

---------------------------------------------------------------------
print("▶ Despegue")
local function takeoff(kind: string): (number?, number, { string })
	local spec = Flight.Specs[kind]
	local s = Flight.new(kind, CFrame.new(0, G, 0))
	local start = s.Pos
	local events = {}
	local liftoff: number? = nil
	local early = false
	for _ = 1, 30 * 60 do
		local inp = input({ Throttle = 1, Pitch = 1 }) -- (tirando de la palanca desde el principio)
		for _, e in Flight.advance(s, inp, 1 / 30, flat()) do
			table.insert(events, e)
		end
		if not s.OnGround and not liftoff then
			liftoff = (s.Pos - start).Magnitude
			early = s.Speed < spec.Vr - 0.5
		end
		if liftoff and s.Pos.Y > G + 40 then
			break
		end
	end
	return liftoff, if early then 1 else 0, events
end
local smallRoll, smallEarly, smallEvents = takeoff("Avioneta")
local bigRoll, bigEarly = takeoff("Avion")
local strip = Airport.Strip.X1 - Airport.Strip.X0
local runway = Airport.Runway.X1 - Airport.Runway.X0
check(smallEarly == 0 and bigEarly == 0, "por debajo de Vr no despega aunque tires de la palanca")
check(smallRoll ~= nil and smallRoll < strip * 0.6, ("la avioneta despega en %d studs: cabe en la pista corta de las Gaviotas (%d)"):format(smallRoll or -1, strip))
check(bigRoll ~= nil and bigRoll > strip and bigRoll < runway * 0.75, ("el avión de línea despega en %d studs: necesita la pista de Valmar (%d)"):format(bigRoll or -1, runway))
check(has(smallEvents, "Despegue"), "al despegar avisa (evento Despegue)")
do
	local s = Flight.new("Avioneta", CFrame.new(0, G, 0))
	run(s, input({ Throttle = 1 }), 8)
	local fast = s.Speed
	run(s, input({ Throttle = -1, Brake = true }), 12)
	check(fast > 30 and s.OnGround and s.Speed == 0, "en tierra acelera con el motor y los frenos lo paran (sin marcha atrás)")
	local s2 = Flight.new("Avioneta", CFrame.new(0, G, 0))
	run(s2, input({ Throttle = 0.4 }), 4)
	local yaw0 = s2.Yaw
	run(s2, input({ Throttle = 0.1, Yaw = 1 }), 2)
	check(s2.OnGround and s2.Yaw < yaw0 - 0.3, "rodando gira a la derecha con el timón (rueda de morro)")
end

---------------------------------------------------------------------
print("▶ En el aire")
do
	local s = airborne("Avioneta", 30, 700)
	local warned, sank = false, 0
	for _ = 1, 20 do
		Flight.advance(s, input({ Pitch = 0.3 }), 1 / 30, flat())
		warned = warned or (s.Stalled and s.Warn == "Perdida")
		sank = math.max(sank, s.Sink)
	end
	check(warned and s.Pitch < math.rad(-10) and sank > 5, "por debajo de la pérdida: aviso PÉRDIDA, el morro baja solo (aunque tires) y el avión cae")
	run(s, input({ Pitch = -0.5, Throttle = 1 }), 1)
	run(s, input({ Pitch = 0.4, Throttle = 1 }), 3)
	check(not s.Stalled and s.Speed > Flight.Specs.Avioneta.Vstall and not s.Crashed, "bajando el morro y con motor gana velocidad y sale de la pérdida")
	local slow = Flight.Specs.Avioneta.Vstall * 0.93
	local clean, flaps = airborne("Avioneta", slow, 300), airborne("Avioneta", slow, 300)
	flaps.Flaps = 2
	run(clean, input(), 0.2)
	run(flaps, input(), 0.2)
	check(clean.Stalled and not flaps.Stalled, "con flaps vuela más despacio sin entrar en pérdida")
	local climb, level = airborne("Avion", 200, 400), airborne("Avion", 200, 400)
	climb.Pitch = math.rad(15)
	run(climb, input({ Throttle = 0 }), 5)
	run(level, input({ Throttle = 0 }), 5)
	check(climb.Speed < level.Speed - 5 and climb.Pos.Y > level.Pos.Y + 50, "subiendo se gana altura y se pierde velocidad")
	local turn = airborne("Avioneta", 110, 300)
	local yaw0 = turn.Yaw
	run(turn, input({ Roll = -1 }), 0.4)
	run(turn, input({ Roll = -0.6 }), 3)
	check(turn.Yaw > yaw0 + 0.3, "al inclinar las alas a la izquierda gira a la izquierda (viraje coordinado)")
	local lvl = airborne("Avioneta", 110, 300)
	lvl.Roll = math.rad(30)
	run(lvl, input(), 5)
	check(math.abs(lvl.Roll) < math.rad(5), "sin tocar nada, las alas vuelven solas a nivel")
end

---------------------------------------------------------------------
print("▶ Aterrizajes")
do
	local A, J = Flight.Specs.Avioneta, Flight.Specs.Avion
	check(Flight.landing(A, 5, 0.05, 0, true, "Pista") == "Suave", "cayendo despacio, tren bajado y alas a nivel: aterrizaje suave")
	check(Flight.landing(A, 14, 0.05, 0, true, "Pista") == "Duro" and Flight.hardDamage(A, 14) > 0, "más fuerte: aterrizaje duro (daña el avión)")
	check(Flight.landing(A, 30, 0.05, 0, true, "Pista") == "Accidente", "mucho más fuerte: accidente")
	check(Flight.landing(J, 4, 0.05, 0, false, "Pista") == "Accidente", "sin tren: accidente")
	check(Flight.landing(A, 4, 0.05, math.rad(25), true, "Suelo") == "Accidente", "tocando con un ala: accidente")
	check(Flight.landing(A, 4, 0.05, 0, true, "Agua") == "Accidente", "en el agua: accidente")
	check(Flight.landing(A, 4, math.rad(-12), 0, true, "Pista") == "Accidente", "entrando de morro: accidente")
	-- Una aproximación de verdad: flaps, despacio, bajando poco a poco hasta tocar
	for _, kind in { "Avioneta", "Avion" } do
		local spec = Flight.Specs[kind]
		local s = airborne(kind, Flight.stallSpeed(spec, 2) * 1.3, G + 60)
		s.Flaps, s.Gear = 2, true
		local events = {}
		for _ = 1, 30 * 90 do
			-- Piloto sencillo: mantiene unos 3 m/s de bajada y la velocidad de aproximación
			local target = Flight.stallSpeed(spec, 2) * 1.3
			local climb = s.Climb
			local inp = input({ Pitch = math.clamp((-4 - climb) * 0.15, -0.5, 0.5), Throttle = math.clamp((target - s.Speed) * 0.2, -1, 1) })
			for _, e in Flight.advance(s, inp, 1 / 30, flat()) do
				table.insert(events, e)
			end
			if s.OnGround or s.Crashed then
				break
			end
		end
		check(has(events, "Suave") and s.OnGround and not s.Crashed, kind .. ": una aproximación con flaps, bajando despacio, acaba en aterrizaje suave")
		run(s, input({ Throttle = -1, Brake = true }), 40)
		check(s.Speed == 0 and s.OnGround, kind .. ": y frena hasta pararse en la pista")
	end
	-- Caer en picado contra el suelo
	local dive = airborne("Avioneta", 120, G + 30)
	dive.Pitch = math.rad(-35)
	local events = run(dive, input({ Pitch = -1 }), 5)
	check(dive.Crashed ~= nil and has(events, "Accidente"), "en picado contra el suelo: accidente")
	-- Sin tren (el avión de línea con el tren subido)
	local belly = airborne("Avion", 100, G + 6)
	belly.Gear, belly.AutoGear = false, false
	belly.Pitch = math.rad(-3)
	run(belly, input(), 5)
	check(belly.Crashed ~= nil, "el avión de línea con el tren subido no puede aterrizar")
	-- Tren automático: sube al despegar y baja al acercarse al suelo
	local auto = Flight.new("Avion", CFrame.new(0, G, 0))
	local up, down = false, false
	for _ = 1, 30 * 40 do
		Flight.advance(auto, input({ Throttle = 1, Pitch = if auto.Speed > Flight.Specs.Avion.Vr then 0.5 else 0 }), 1 / 30, flat())
		up = up or (not auto.OnGround and not auto.Gear)
		if auto.Pos.Y > G + 150 then
			break
		end
	end
	auto.Pitch = math.rad(-6)
	local warnedGear = false
	for _ = 1, 30 * 30 do
		Flight.advance(auto, input({ Throttle = -0.2 }), 1 / 30, flat())
		down = down or (auto.Gear and auto.Pos.Y < G + 40)
		if auto.OnGround or auto.Crashed then
			break
		end
	end
	check(up and down, "tren automático del avión de línea: sube al despegar y baja cerca del suelo")
	local manual = airborne("Avion", 150, G + 70)
	manual.Gear, manual.AutoGear, manual.Pitch = false, false, math.rad(-4)
	for _ = 1, 30 * 2 do
		Flight.advance(manual, input(), 1 / 30, flat())
		warnedGear = warnedGear or manual.Warn == "Tren"
	end
	check(warnedGear and not manual.Gear, "con el tren a mano (G) y subido, bajando cerca del suelo avisa: ¡BAJA EL TREN!")
	-- Al agua
	local sea = airborne("Avioneta", 60, G + 3)
	sea.Pitch = math.rad(-2)
	run(sea, input(), 4, flat("Agua"))
	check(sea.Crashed == "Has caído al agua", "amerizar es accidente")
end

---------------------------------------------------------------------
print("▶ Choques")
do
	local wall = {
		ground = function(_p)
			return G, "Suelo"
		end,
		hit = function(_cf, _move)
			return "Torre de control"
		end,
	}
	local s = airborne("Avion", 180, 120)
	local events = run(s, input(), 0.2, wall)
	check(s.Crashed ~= nil and string.find(s.Crashed, "Torre de control", 1, true) ~= nil and has(events, "Accidente"), "en vuelo, tocar un edificio es accidente")
	local taxi = Flight.new("Avioneta", CFrame.new(0, G, 0))
	taxi.Speed = 8
	local ev = run(taxi, input({ Throttle = 0.2 }), 0.2, wall)
	check(taxi.Crashed == nil and has(ev, "Choque") and taxi.Speed == 0, "rodando despacio, tocar algo solo para el avión (no explota)")
	local fast = Flight.new("Avion", CFrame.new(0, G, 0))
	fast.Speed = 60
	run(fast, input(), 0.2, wall)
	check(fast.Crashed ~= nil, "rodando deprisa contra algo: accidente")
end

---------------------------------------------------------------------
print("▶ Límites del mapa y techo de vuelo")
do
	local B = Flight.Bounds
	local s = airborne("Avion", 220, 500, B.X1 - 300, 0)
	s.Yaw = -math.pi / 2 -- (hacia el este, hacia el borde)
	local maxX = -math.huge
	local warned = false
	for _ = 1, 30 * 40 do
		Flight.advance(s, input({ Throttle = 0.7 }), 1 / 30, flat())
		maxX = math.max(maxX, s.Pos.X)
		warned = warned or s.Warn == "Limite"
	end
	local look = Flight.look(s)
	check(warned and maxX < B.X1 + 200 and look.X < 0, ("cerca del borde avisa y gira solo hacia dentro (como mucho x = %d)"):format(maxX))
	local up = airborne("Avioneta", 140, B.Ceiling - 150)
	local top = 0
	local roof = false
	for _ = 1, 30 * 30 do
		Flight.advance(up, input({ Pitch = 1, Throttle = 1 }), 1 / 30, flat())
		top = math.max(top, up.Pos.Y)
		roof = roof or up.Warn == "Techo"
	end
	check(roof and top <= B.Ceiling + 1e-3, ("con el morro arriba no pasa del techo de vuelo (%d)"):format(B.Ceiling))
	check(Flight.heading(Flight.new("Avioneta", CFrame.new())) == 0 and Flight.compass(90) == "E" and Flight.compass(225) == "SO", "rumbo del panel: 0 = norte, 90 = este (puntos cardinales en español)")
end

---------------------------------------------------------------------
print("▶ Palanca analógica (móvil y mando: Flight.stickInput) en el modelo de vuelo")
do
	-- (la palanca: x a la derecha, y hacia ABAJO como la pantalla). Por defecto, TIRAR HACIA ABAJO SUBE EL
	-- MORRO (como un avión de verdad: el dueño tiraba hacia abajo para despegar y acabó en el agua)
	local p, r, y = Flight.stickInput(Vector2.new(0, 1))
	check(p == 1 and r == 0 and y == 0, "por defecto, palanca hacia abajo (tirar) = morro arriba")
	p = Flight.stickInput(Vector2.new(0, -1))
	check(p == -1, "por defecto, palanca hacia arriba (empujar) = morro abajo")
	p = Flight.stickInput(Vector2.new(0, -1), true)
	local p2 = Flight.stickInput(Vector2.new(0, 1), true)
	check(p == 1 and p2 == -1, "con «Tirar hacia abajo para subir: No» (invert), arriba sube el morro y abajo lo baja")
	p, r, y = Flight.stickInput(Vector2.new(1, 0))
	check(p == 0 and r == 1 and y > 0 and y < 1, "a la derecha: alabeo a la derecha y un poco de timón (sin botones de timón)")
	p, r = Flight.stickInput(Vector2.new(-0.6, 0.6))
	check(p > 0.5 and r < -0.5, "en diagonal (abajo a la izquierda): sube el morro y alabea a la vez (todas las direcciones)")
	local function stick(x: number, yy: number, extra: { [string]: any }?): any
		local pp, rr, yw = Flight.stickInput(Vector2.new(x, yy))
		local t = { Pitch = pp, Roll = rr, Yaw = yw }
		for k, v in extra or {} do
			t[k] = v
		end
		return input(t)
	end
	for _, kind in { "Avioneta", "Avion" } do
		local spec = Flight.Specs[kind]
		-- Despegue: motor a tope, palanca neutra hasta Vr y luego arriba
		local s = Flight.new(kind, CFrame.new(0, G, 0))
		local rotatedEarly = false
		local events = {}
		for _ = 1, 30 * 90 do
			local up = s.Speed >= spec.Vr
			for _, e in Flight.advance(s, stick(0, if up then 0.8 else 0, { Throttle = 1 }), 1 / 30, flat()) do
				table.insert(events, e)
			end
			rotatedEarly = rotatedEarly or (s.OnGround and s.Speed < spec.Vr * 0.9 and s.Pitch > 0.01)
			if not s.OnGround and s.Pos.Y > G + 60 then
				break
			end
		end
		check(has(events, "Despegue") and not rotatedEarly and s.Pitch > math.rad(4), kind .. ": tirando de la palanca hacia abajo, en tierra el morro sube al pasar Vr y despega")
		-- Subir: tirar de la palanca (hacia abajo) un rato
		local y0 = s.Pos.Y
		run(s, stick(0, 0.5, { Throttle = 1 }), 6)
		check(s.Pos.Y > y0 + 80 and s.Climb > 3 and not s.Crashed, ("%s: palanca hacia abajo (tirar) = sube (+%d studs)"):format(kind, s.Pos.Y - y0))
		-- Nivelar: empujar (palanca hacia arriba) hasta el morro a nivel y soltar; vuela recto
		for _ = 1, 30 * 10 do
			if s.Pitch <= math.rad(0.5) then
				break
			end
			Flight.advance(s, stick(0, -0.6, { Throttle = 0.7 }), 1 / 30, flat())
		end
		run(s, stick(0, 0, { Throttle = 0.7 }), 1)
		local yl = s.Pos.Y
		run(s, stick(0, 0, { Throttle = 0.7 }), 5)
		check(math.abs(s.Pos.Y - yl) < 40 and not s.Stalled, ("%s: con el morro a nivel y la palanca suelta, vuelo nivelado (%+d studs en 5 s)"):format(kind, s.Pos.Y - yl))
		-- Bajar: empujar (palanca hacia arriba)
		local yd = s.Pos.Y
		run(s, stick(0, -0.5, { Throttle = 0.4 }), 3)
		check(s.Pos.Y < yd - 30 and s.Climb < -3, ("%s: palanca hacia arriba (empujar) = baja (%d studs)"):format(kind, s.Pos.Y - yd))
		-- Girar con la palanca a un lado (alabeo + timón automático), en crucero y con altura
		s = airborne(kind, spec.Vr * 1.9, 400)
		s.Throttle = 0.8
		local yaw0 = s.Yaw
		run(s, stick(0.7, 0, { Throttle = 0.8 }), 2.5)
		check(s.Roll < math.rad(-10) and s.Yaw < (yaw0 - 0.12), ("%s: palanca a la derecha = se inclina y gira a la derecha (alabeo %.0f°, giro %.2f rad)"):format(kind, math.deg(s.Roll), s.Yaw - yaw0))
		-- En tierra, a los lados gira la rueda de morro
		local taxi = Flight.new(kind, CFrame.new(0, G, 0))
		run(taxi, input({ Throttle = 0.5 }), 4)
		local ty = taxi.Yaw
		run(taxi, stick(-1, 0, { Throttle = 0 }), 1.5)
		check(taxi.OnGround and taxi.Yaw > ty + 0.15, kind .. ": rodando, la palanca a la izquierda gira la rueda de morro a la izquierda")
		-- Techo: tirando sin parar, nunca por encima de Flight.Bounds.Ceiling
		local high = airborne(kind, spec.Vmax * 0.8, Flight.Bounds.Ceiling - 300)
		local top = 0
		for _ = 1, 30 * 40 do
			Flight.advance(high, stick(0, 1, { Throttle = 1 }), 1 / 30, flat())
			top = math.max(top, high.Pos.Y)
		end
		check(top <= Flight.Bounds.Ceiling + 1e-3 and not high.Crashed, ("%s: tirando sin parar no pasa del techo (%d)"):format(kind, Flight.Bounds.Ceiling))
		-- Protección de pérdida: cerca de Vstall, tirar sube el morro mucho menos que con velocidad
		local slow, fast = airborne(kind, spec.Vstall * 1.05, 600), airborne(kind, spec.Vstall * 2, 600)
		slow.Pitch, fast.Pitch = math.rad(5), math.rad(5)
		run(slow, stick(0, 1), 0.3)
		run(fast, stick(0, 1), 0.3)
		check(slow.Pitch - math.rad(5) < (fast.Pitch - math.rad(5)) * 0.5, kind .. ": cerca de la pérdida, tirar apenas sube el morro (protección arcade)")
	end
end

---------------------------------------------------------------------
print("▶ Giros estables, modo acrobático, looping y tonel (vídeo del dueño v117: «se bugea cuando vas para el lado»)")
do
	local function stick(x: number, yy: number, extra: { [string]: any }?): any
		local pp, rr, yw = Flight.stickInput(Vector2.new(x, yy))
		local t = { Pitch = pp, Roll = rr, Yaw = yw }
		for k, v in extra or {} do
			t[k] = v
		end
		return input(t)
	end
	for _, kind in { "Avioneta", "Avion" } do
		local spec = Flight.Specs[kind]
		local cruise = spec.Vr * 1.8
		-- Palanca a tope a un lado 10 s en crucero: inclina hasta el límite, gira, no pierde altura ni entra
		-- en pérdida (antes seguía alabeando hasta ponerse de canto, se caía y entraba en pérdida)
		for _, side in { 1, -1 } do
			local t = airborne(kind, cruise, 500)
			t.Throttle = 0.7
			local y0, maxBank, stalled = t.Pos.Y, 0, false
			for _ = 1, 300 do
				Flight.advance(t, stick(side, 0, { Throttle = 0 }), 1 / 30, flat())
				maxBank = math.max(maxBank, math.abs(t.Roll))
				stalled = stalled or t.Stalled
			end
			check(math.abs(t.Pos.Y - y0) < 30 and maxBank <= spec.BankLimit + math.rad(1) and not stalled and not t.Crashed and t.Throttle == 0.7,
				("%s: palanca a tope %s 10 s: inclina como mucho %.0f° (límite %.0f°), %+d studs de altura, sin pérdida y el motor donde estaba"):format(kind, if side > 0 then "a la derecha" else "a la izquierda", math.deg(maxBank), math.deg(spec.BankLimit), t.Pos.Y - y0))
			local back = 0
			while math.abs(t.Roll) > math.rad(2) and back < 5 do
				Flight.advance(t, stick(0, 0, { Throttle = 0 }), 1 / 30, flat())
				back += 1 / 30
			end
			check(back <= 1.5, ("%s: al soltar la palanca las alas vuelven a nivel solas (%.1f s)"):format(kind, back))
		end
		-- El motor se queda donde lo pone el piloto (también después de despegar con la ayuda)
		local s = Flight.new(kind, CFrame.new(0, G, 0))
		for _ = 1, 30 * 60 do
			Flight.advance(s, stick(0, if s.Speed >= spec.Vr then 0.8 else 0, { Throttle = 1 }), 1 / 30, flat())
			if not s.OnGround and s.Pos.Y > G + 40 then
				break
			end
		end
		run(s, stick(0, 0.2, { Throttle = 0 }), 10)
		check(not s.OnGround and s.Throttle == 1 and not s.Crashed, ("%s: tras despegar a tope y soltar MOTOR +, el motor sigue al %d%%"):format(kind, math.floor(s.Throttle * 100 + 0.5)))
		-- Pérdida suave: despacio y con motor, sale sola y sin caerse de lado
		local st = airborne(kind, Flight.stallSpeed(spec, 0) * 0.8, 600)
		st.Throttle = 1
		st.Roll = math.rad(30)
		run(st, input(), 0.2)
		local wasStalled = st.Stalled
		local sy = st.Pos.Y
		run(st, input(), 6)
		check(wasStalled and not st.Stalled and math.abs(st.Roll) < math.rad(3) and sy - st.Pos.Y < 150 and not st.Crashed,
			("%s: pérdida suave: el morro baja un poco, las alas a nivel y sale sola con motor (%d studs perdidos)"):format(kind, sy - st.Pos.Y))
		-- LOOPING asistido: vuelve a la misma altura y rumbo, sin pérdida y a la misma velocidad
		local fast = cruise * 1.2
		local hi = G + 2 * Flight.loopRadius(spec, fast) + Flight.ManeuverMargin + 60
		local l = airborne(kind, fast, hi)
		l.Throttle = 0.8
		local ok = Flight.maneuver(l, "Loop", nil, flat())
		local ly, lyaw, top, lowSpeed, stalledL, inverted = l.Pos.Y, l.Yaw, l.Pos.Y, math.huge, false, false
		local events = {}
		local tt = 0
		while l.Maneuver and tt < 20 do
			for _, e in Flight.advance(l, input(), 1 / 30, flat()) do
				table.insert(events, e)
			end
			top = math.max(top, l.Pos.Y)
			lowSpeed = math.min(lowSpeed, l.Speed)
			stalledL = stalledL or l.Stalled
			inverted = inverted or Flight.cframe(l).UpVector.Y < -0.9
			tt += 1 / 30
		end
		local dyaw = math.abs(((l.Yaw - lyaw + math.pi) % (2 * math.pi)) - math.pi)
		check(ok and inverted and math.abs(l.Pos.Y - ly) < 3 and dyaw < 0.02 and top - ly > 1.8 * Flight.loopRadius(spec, fast) and not stalledL and lowSpeed >= fast - 0.01 and has(events, "ManiobraFin") and math.abs(tt - spec.LoopTime) < 0.1,
			("%s: LOOPING: 360° por encima (boca abajo arriba, sube %d studs) y vuelve a la misma altura (%+.1f) y rumbo, sin pérdida, en %.1f s"):format(kind, top - ly, l.Pos.Y - ly, tt))
		-- Justo después: recarga
		local again, why = Flight.maneuver(l, "Roll", 1, flat())
		check(not again and why == "Recarga", kind .. ": otra maniobra justo después: espera (recarga)")
		run(l, input(), Flight.ManeuverCooldown + 0.1)
		-- TONEL asistido a la izquierda: 360° de alabeo sin cambiar de altura ni de rumbo
		l.Roll, l.Pitch = 0, 0
		local ry, ryaw = l.Pos.Y, l.Yaw
		local okR = Flight.maneuver(l, "Roll", -1, flat())
		local invertedR, turned, last = false, 0, Flight.cframe(l).RightVector
		tt = 0
		while l.Maneuver and tt < 20 do
			Flight.advance(l, input(), 1 / 30, flat())
			local now = Flight.cframe(l).RightVector
			turned += math.acos(math.clamp(now:Dot(last), -1, 1))
			last = now
			invertedR = invertedR or Flight.cframe(l).UpVector.Y < -0.9
			tt += 1 / 30
		end
		local dyawR = math.abs(((l.Yaw - ryaw + math.pi) % (2 * math.pi)) - math.pi)
		check(okR and invertedR and math.abs(math.deg(turned) - 360) < 3 and math.abs(l.Roll) < math.rad(1) and math.abs(l.Pos.Y - ry) < 3 and dyawR < 0.02,
			("%s: TONEL: un giro entero de alabeo (%.0f°) sin perder altura (%+.1f) ni rumbo"):format(kind, math.deg(turned), l.Pos.Y - ry))
		-- Se niega: despacio, bajo o en tierra
		local slow = airborne(kind, Flight.stallSpeed(spec, 0) * 1.1, 900)
		local okS, whyS, kmh = Flight.maneuver(slow, "Loop", nil, flat())
		local low = airborne(kind, fast, G + 30)
		local okL, whyL, meters = Flight.maneuver(low, "Loop", nil, flat())
		local okRl, whyRl = Flight.maneuver(airborne(kind, fast, G + 20), "Roll", 1, flat())
		local okG, whyG = Flight.maneuver(Flight.new(kind, CFrame.new(0, G, 0)), "Roll", 1, flat())
		check(not okS and whyS == "Lento" and (kmh or 0) > 0 and not okL and whyL == "Bajo" and (meters or 0) > 0 and not okRl and whyRl == "Bajo" and not okG and whyG == "EnTierra" and slow.Maneuver == nil,
			("%s: se niega con motivo: demasiado lento (mín. %s km/h), demasiado bajo (sube a %s m) o en tierra"):format(kind, tostring(kmh), tostring(meters)))
		-- MODO ACROBÁTICO: sin topes (la palanca da la vuelta entera) y sin nivelarse solo
		local a = airborne(kind, fast, 900)
		a.Throttle = 1
		a.Acro = true
		local inv = false
		for _ = 1, 30 * 4 do
			Flight.advance(a, stick(1, 0, { Throttle = 0 }), 1 / 30, flat())
			inv = inv or Flight.cframe(a).UpVector.Y < -0.5
		end
		local normal = airborne(kind, fast, 900)
		local invN = false
		for _ = 1, 30 * 4 do
			Flight.advance(normal, stick(1, 0, { Throttle = 0 }), 1 / 30, flat())
			invN = invN or Flight.cframe(normal).UpVector.Y < 0.3
		end
		check(inv and not invN and not a.Crashed, kind .. ": modo acrobático: la palanca a un lado da la vuelta entera (boca abajo); en el normal nunca pasa del límite")
		local p = airborne(kind, fast, 450)
		p.Throttle = 1
		p.Acro = true
		local over = false
		for _ = 1, 30 * 6 do
			Flight.advance(p, stick(0, 1, { Throttle = 0 }), 1 / 30, flat())
			over = over or (Flight.cframe(p).UpVector.Y < -0.5 and Flight.look(p).Y > -0.9)
		end
		check(over and not p.Crashed, kind .. ": modo acrobático: tirando de la palanca pasa por la vertical y sigue por arriba (looping a mano)")
	end
end

print("▶ Despegar en cada pista (vídeo del dueño: «sigue sin subir de vuelo» y acabó en el agua)")
-- El mundo de verdad del aeropuerto: asfalto en las pistas y calles de rodaje, hierba en la tierra
-- ganada al mar y en la isla, agua alrededor; y cuánta pista queda (Airport.runwayLeft)
local function airportEnv(): any
	return {
		ground = function(p)
			if Airport.paved(p.X, p.Z, 3) then
				return G, "Pista"
			end
			local L = Airport.Land
			if p.X >= L.X0 and p.X <= L.X1 and p.Z >= L.Z0 and p.Z <= L.Z1 then
				return G, "Suelo"
			end
			local S = Airport.Strip
			if p.X >= S.X0 - 60 and p.X <= S.X1 + 60 and math.abs(p.Z - S.Z) < 120 then
				return G, "Suelo"
			end
			return G - 0.4, "Agua"
		end,
		runway = function(p, yaw)
			return (Airport.runwayLeft(p, yaw))
		end,
	}
end
local WEST, EAST = math.pi / 2, -math.pi / 2 -- (rumbos: el morro a -X y a +X)
-- Desde parado en la cabecera, MOTOR + mantenido y la palanca hacia abajo desde el principio (como el
-- dueño): dónde se separa del suelo y cuánta pista sobra
local function rollFrom(kind: string, x: number, z: number, yaw: number, flaps: number, stickY: number, env: any): { [string]: any }
	local s = Flight.new(kind, CFrame.new(x, G, z) * CFrame.Angles(0, yaw, 0))
	s.Flaps = flaps
	local start = s.Pos
	local out = { Liftoff = nil, Left = nil, Crashed = nil, Cue = false, Warned = false, Auto = false, Climbed = false }
	for _ = 1, 30 * 60 do
		local p, r, y = Flight.stickInput(Vector2.new(0, stickY))
		local left = s.RunwayLeft
		Flight.advance(s, input({ Pitch = p, Roll = r, Yaw = y, Throttle = 1 }), 1 / 30, env)
		out.Cue = out.Cue or s.Cue == "Rotar"
		out.Warned = out.Warned or s.Warn == "FinPista"
		out.Auto = out.Auto or s.AutoRotated == true
		if not s.OnGround and not out.Liftoff then
			out.Liftoff = (s.Pos - start).Magnitude
			out.Left = left
		end
		if s.Crashed then
			out.Crashed = s.Crashed
			break
		end
		if out.Liftoff and s.Pos.Y > G + 25 then
			out.Climbed = true
			break
		end
	end
	return out
end
do
	local env = airportEnv()
	local R, S = Airport.Runway, Airport.Strip
	local cases = {
		{ "Avioneta", "Pista de Valmar", R, 0.6 },
		{ "Avioneta", "Pista de las Gaviotas", S, 0.5 },
		{ "Avion", "Pista de Valmar", R, 0.5 },
	}
	for _, c in cases do
		local kind, name, rect, margin = c[1], c[2], c[3], c[4]
		local length = rect.X1 - rect.X0
		local worst = math.huge
		local bad = {}
		for _, dir in { { rect.X1 - 2, "hacia el oeste" }, { rect.X0 + 2, "hacia el este" } } do
			local x, label = dir[1], dir[2]
			local yaw = if x > (rect.X0 + rect.X1) / 2 then WEST else EAST
			for flaps = 0, 2 do
				local res = rollFrom(kind, x, rect.Z, yaw, flaps, 1, env)
				local left = if res.Liftoff then length - 2 - res.Liftoff else -1
				worst = math.min(worst, left)
				if not res.Liftoff or not res.Climbed or res.Crashed or left < length * margin then
					table.insert(bad, ("%s flaps %d: %s"):format(label, flaps, if res.Liftoff then ("despega a %d, sobran %d"):format(res.Liftoff, left) else tostring(res.Crashed or "no despega")))
				end
			end
		end
		check(#bad == 0, ("%s en la %s (%d studs): desde parado, motor a tope y tirando, despega en ambos sentidos con flaps 0/1/2 y sobran como poco %d studs (%d%%)%s"):format(kind, name, length, worst, math.floor(100 * worst / length), if #bad > 0 then " — " .. table.concat(bad, "; ") else ""))
	end
	-- Lo que hizo el dueño, ya con la convención nueva: entra por la salida del medio, motor a tope,
	-- flaps 2 y palanca abajo todo el rato: despega y no acaba en el agua
	local mid = Airport.Taxiway.Exits[2]
	local owner = rollFrom("Avioneta", mid, R.Z, WEST, 2, 1, env)
	check(owner.Liftoff ~= nil and owner.Climbed and not owner.Crashed and owner.Left and owner.Left > 200, ("el vídeo del dueño (salida del medio, hacia el oeste, flaps 2, palanca abajo): despega a %d studs y sobran %d de pista"):format(owner.Liftoff or -1, owner.Left or -1))
	-- Y quien empuja hacia arriba (la convención de antes) con el motor a tope: la ayuda le despega antes
	-- del final de la pista (y le sube unos segundos), nunca acaba en el agua
	for _, kind in { "Avioneta", "Avion" } do
		local from = if kind == "Avion" then R.X1 - 2 else mid
		local wrong = rollFrom(kind, from, R.Z, WEST, 1, -1, env)
		check(wrong.Auto and wrong.Liftoff ~= nil and wrong.Climbed and not wrong.Crashed and wrong.Warned and wrong.Cue, ("%s: empujando al revés y a tope, avisa (FIN DE PISTA, «tira para despegar») y la ayuda lo despega antes del agua (sobran %d studs)"):format(kind, wrong.Left or -1))
	end
end
do
	-- La pista: la ayuda («tira para despegar») solo pasada Vr y sin tirar; el aviso solo cerca del final
	local A = Flight.Specs.Avioneta
	local env = airportEnv()
	local R = Airport.Runway
	local s = Flight.new("Avioneta", CFrame.new(R.X1 - 2, G, R.Z) * CFrame.Angles(0, WEST, 0))
	s.Speed, s.Throttle = A.Vr * 0.7, 1
	Flight.advance(s, input({ Throttle = 1 }), 1 / 30, env)
	check(s.Cue == nil and s.Warn == nil and s.RunwayLeft and s.RunwayLeft > 800, ("por debajo de Vr y con pista de sobra: ni ayuda ni aviso (quedan %d studs)"):format(s.RunwayLeft or -1))
	s.Speed = A.Vr + 2
	Flight.advance(s, input({ Throttle = 1 }), 1 / 30, env)
	check(s.Cue == "Rotar", "pasada Vr sin tirar: la ayuda «tira hacia abajo para despegar» (Cue = Rotar)")
	Flight.advance(s, input({ Throttle = 1, Pitch = 1 }), 1 / 30, env)
	check(s.Cue == nil, "tirando ya, la ayuda se quita")
	local e = Flight.new("Avioneta", CFrame.new(R.X0 + 110, G, R.Z) * CFrame.Angles(0, WEST, 0))
	e.Speed, e.Throttle = 40, 0.3
	Flight.advance(e, input({ Throttle = 0 }), 1 / 30, env)
	check(e.Warn == "FinPista" and not e.AutoRotated, "cerca del final de la pista: aviso FIN DE PISTA (sin motor a tope no rota solo)")
	local across = Airport.runwayLeft(Vector3.new((R.X0 + R.X1) / 2, G, R.Z), 0)
	local off = Airport.runwayLeft(Vector3.new((R.X0 + R.X1) / 2, G, R.Z - 200), WEST)
	check(across == nil and off == nil and Airport.runwayLeft(Vector3.new(R.X0 + 100, G, R.Z), EAST) == R.X1 - R.X0 - 100, "Airport.runwayLeft: lo que queda en el sentido de la marcha; nada cruzando la pista o fuera de ella")
	-- El tren de la avioneta ya se sube (el botón «Tren» vuelve también en la avioneta)
	check(not A.FixedGear and A.BellyClear > 0, "la avioneta tiene tren retráctil (el botón «Tren» sale también en ella)")
	local belly = airborne("Avioneta", 60, G + 4)
	belly.Gear, belly.AutoGear, belly.Pitch = false, false, math.rad(-2)
	run(belly, input(), 4)
	check(belly.Crashed == "Has aterrizado sin el tren", "la avioneta con el tren subido no puede aterrizar")
end

---------------------------------------------------------------------
-- Modelos (con un mapa construido)
---------------------------------------------------------------------
local placePath = process.args[1]
if placePath then
	print("▶ Modelos de los aviones del mapa")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local town = game:GetService("Workspace"):FindFirstChild("Town")
	local folder = town and town:FindFirstChild("Aviones")
	check(folder ~= nil, "están los aviones (Town.Aviones)")
	local budget = { Avion = 110, Avioneta = 64 } -- (Kit/PlaneModel.Budget)
	local function boxOf(pose: any, d: any): (any, any)
		local local_ = pose:ToObjectSpace(d.CFrame)
		local c = { local_:GetComponents() }
		local s = d.Size
		local hx = (math.abs(c[4]) * s.X + math.abs(c[5]) * s.Y + math.abs(c[6]) * s.Z) / 2
		local hy = (math.abs(c[7]) * s.X + math.abs(c[8]) * s.Y + math.abs(c[9]) * s.Z) / 2
		local hz = (math.abs(c[10]) * s.X + math.abs(c[11]) * s.Y + math.abs(c[12]) * s.Z) / 2
		return Vector3.new(c[1] - hx, c[2] - hy, c[3] - hz), Vector3.new(c[1] + hx, c[2] + hy, c[3] + hz)
	end
	local models = {}
	for _, spec in Airport.Planes do
		table.insert(models, { Id = spec.Id, Kind = spec.Kind, Pose = Airport.parkPose(Airport.Routes[spec.Routes[1]]), Pilot = false })
	end
	for _, spec in Airport.PilotPlanes do
		table.insert(models, { Id = spec.Id, Kind = spec.Kind, Pose = spec.Pose, Pilot = true })
	end
	for _, info in models do
		local m = folder and folder:FindFirstChild(info.Id)
		local kind = Airport.Kinds[info.Kind]
		if not m then
			check(false, info.Id .. ": falta el modelo")
			continue
		end
		local parts, seats, pilotSeat = 0, 0, 0
		local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		local wheelsLow = math.huge
		local shapes = {}
		local red, green = nil, nil
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
				local a, b = boxOf(info.Pose, d)
				if d.Transparency < 1 then
					lo = Vector3.new(math.min(lo.X, a.X), math.min(lo.Y, a.Y), math.min(lo.Z, a.Z))
					hi = Vector3.new(math.max(hi.X, b.X), math.max(hi.Y, b.Y), math.max(hi.Z, b.Z))
				end
				if d.Name == "Wheel" then
					wheelsLow = math.min(wheelsLow, a.Y)
				end
				if d:IsA("Seat") then
					if d.Name == "PilotSeat" then
						pilotSeat += 1
					else
						seats += 1
					end
				end
				if d.Name == "NavLight" then
					local x = (a.X + b.X) / 2
					if x < 0 then
						red = d.Color
					else
						green = d.Color
					end
				end
				local cx = (a.X + b.X) / 2
				if math.abs(cx) > 0.3 then
					table.insert(shapes, { Name = d.Name, X = cx, Y = (a.Y + b.Y) / 2, Z = (a.Z + b.Z) / 2, W = b.X - a.X })
				end
			end
		end
		check(parts <= budget[info.Kind], ("%s: %d piezas (presupuesto %d)"):format(info.Id, parts, budget[info.Kind]))
		-- Simetría: cada pieza de un lado tiene su gemela al otro (alas, motores, tren, luces…)
		local lonely = {}
		for _, a in shapes do
			local found = false
			for _, b in shapes do
				if b.Name == a.Name and math.abs(b.X + a.X) < 0.05 and math.abs(b.Y - a.Y) < 0.05 and math.abs(b.Z - a.Z) < 0.05 and math.abs(b.W - a.W) < 0.05 then
					found = true
					break
				end
			end
			if not found and a.Name ~= "PilotSeat" and a.Name ~= "Seat" and a.Name ~= "SeatBack" and a.Name ~= "CopilotSeat" and a.Name ~= "LandingLight" and a.Name ~= "Propeller" and a.Name ~= "BoardPoint" then
				table.insert(lonely, a.Name)
			end
		end
		check(#lonely == 0, ("%s: alas, motores, tren y luces simétricos%s"):format(info.Id, if #lonely > 0 then " (sin gemela: " .. table.concat(lonely, ", ") .. ")" else ""))
		check(red == Color3.fromRGB(255, 40, 40) and green == Color3.fromRGB(40, 255, 90), info.Id .. ": luz roja en el ala izquierda y verde en la derecha")
		check(math.abs(wheelsLow) < 0.05, ("%s: el tren toca el suelo (rueda más baja a %.2f)"):format(info.Id, wheelsLow))
		check(lo.Y > -0.05, ("%s: nada se mete bajo el suelo (%.2f)"):format(info.Id, lo.Y))
		local length, span = hi.Z - lo.Z, hi.X - lo.X
		check(math.abs(length - kind.Length) <= 3 and math.abs(span - kind.Span) <= 1.5 and lo.Z < 0 and hi.Z > 0, ("%s: mide %.1f de largo y %.1f de envergadura (Airport.Kinds: %d y %d)"):format(info.Id, length, span, kind.Length, kind.Span))
		check(-lo.Z > hi.Z - 6, info.Id .. ": el morro va hacia delante (-Z)")
		local root = m:FindFirstChild("Root")
		check(root ~= nil and m.PrimaryPart == root and m:GetAttribute("NeedsWeld") == true, info.Id .. ": con su suelo Root (la raíz) y por soldar al arrancar")
		if info.Pilot then
			check(pilotSeat == 1 and seats == kind.Seats - (if info.Kind == "Avioneta" then 1 else 0) and m:FindFirstChild("BoardPoint") ~= nil, ("%s: asiento del piloto, %d de pasajero y punto para subir"):format(info.Id, seats))
			check(m:HasTag("PilotPlane") and m:GetAttribute("PilotPlane") == info.Id and m.ModelStreamingMode == Enum.ModelStreamingMode.Atomic and not m:HasTag("Plane"), info.Id .. ": se pilota (tag PilotPlane), se carga entero (Atomic) y no es de los vuelos")
			local rootWant = Airport.rootCFrame(info.Kind, info.Pose).Position
			check(root ~= nil and (root.CFrame.Position - rootWant).Magnitude < 0.05, info.Id .. ": espera en su sitio")
		else
			check(pilotSeat == 0 and seats == kind.Seats and m.ModelStreamingMode == Enum.ModelStreamingMode.Persistent, ("%s: %d asientos, sin piloto (vuela solo) y siempre cargado"):format(info.Id, seats))
		end
		local gear, props = 0, 0
		for _, d in m:GetDescendants() do
			if d:GetAttribute("Gear") then
				gear += 1
			end
			if d:GetAttribute("Prop") then
				props += 1
			end
		end
		if info.Kind == "Avion" then
			check(gear >= 9, info.Id .. ": tren de morro y principal que se sube (Gear)")
		else
			check(props == 2, info.Id .. ": hélice con palas y disco (Prop)")
		end
	end
	-- Los aparcados no estorban a los aviones de los vuelos al rodar (ni a sus puestos)
	local blocked = {}
	for _, spec in Airport.PilotPlanes do
		local k = Airport.Kinds[spec.Kind]
		local p = spec.Pose.Position
		for id, route in Airport.Routes do
			local half = Airport.Kinds[route.Kind].Span / 2
			local t = 0
			while t <= route.Total do
				local cf = Airport.pose(route, t)
				local q = cf.Position
				if q.Y < G + 1 then
					local dx, dz = math.abs(q.X - p.X), math.abs(q.Z - p.Z)
					local reach = half + math.max(k.Span, k.Length) / 2 + 6
					if dx < reach and dz < reach and (q - p).Magnitude < half + math.max(k.Span, k.Length) / 2 + 6 then
						blocked[spec.Id] = id
					end
				end
				t += 0.5
			end
		end
	end
	local n = 0
	for plane, route in blocked do
		n += 1
		print(("    %s estorba a la ruta %s"):format(plane, route))
	end
	check(n == 0, "los aviones de los jugadores esperan lejos de por donde ruedan los de los vuelos")
	-- El aeroclub: su mostrador
	local desk = nil
	for _, d in town:GetDescendants() do
		if d:HasTag("Aeroclub") then
			desk = d
		end
	end
	check(desk ~= nil and math.abs(desk.CFrame.Position.X - Airport.Aeroclub.X) < 1, "el mostrador del aeroclub está en el hangar (tag Aeroclub)")
else
	print("▶ (sin mapa: no se miran los modelos; pásale un mapa construido)")
end

print("")
if failures == 0 then
	print("✅ Vuelo: todo correcto")
	process.exit(0)
end
print(("❌ %d comprobaciones fallidas"):format(failures))
process.exit(1)
