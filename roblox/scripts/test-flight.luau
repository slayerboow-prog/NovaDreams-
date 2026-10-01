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

local Vector3, CFrame, Color3, Enum = roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Enum

local function load(path: string): any
	local env = setmetatable({ Vector3 = Vector3, CFrame = CFrame, Color3 = Color3, Enum = Enum, script = { Parent = {} } }, { __index = getfenv(1) })
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
	run(turn, input({ Roll = -0.2 }), 3)
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
	belly.Gear = false
	belly.Pitch = math.rad(-3)
	run(belly, input(), 5)
	check(belly.Crashed ~= nil, "el avión de línea con el tren subido no puede aterrizar")
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
