-- Prueba de nadar y bucear (Shared/Swim, Controllers/Swimming, Controllers/SeaMotion y los botones)
-- FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-swim.luau
--
-- El fallo que arregla (v68, móvil): nadando en la playa el cuerpo daba vueltas (boca abajo, de lado),
-- pasaba de la superficie al fondo en medio segundo, se quedaba tumbado en la arena, la cámara se
-- metía en el fondo y el aire subía y bajaba (18 s, 20 s…) sin bucear. Comprueba que:
--   * "bajo el agua" se mide con el centro del cuerpo y con margen: flotando o nadando en la
--     superficie nunca lo estás (el aire no baja), buceando sí, y al salir se recupera
--   * flotando, el cuerpo se queda a su altura (cabeza fuera), sin subir y bajar
--   * Bucear baja, soltar deja el cuerpo quieto a esa profundidad (flotabilidad neutra), nunca baja
--     hasta tumbarse en el fondo, Subir vuelve a la superficie
--   * donde se hace pie no se nada (se anda por el fondo)
--   * la postura nunca pone el cuerpo boca abajo (Root) ni lo hace saltar de postura a cada frame
--   * el control (Swimming) enciende la flotación y el "derecho" (AlignOrientation) solo en el agua,
--     y la cámara nunca queda dentro de la arena ni partida en la superficie
--   * nadando, el racimo táctil esconde pelear y armas, y Bucear/Subir ocupan sus huecos

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Enum = roblox.CFrame, roblox.Vector3, roblox.Enum

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local Swim = luau.load(fs.readFile("src/shared/Swim.luau"), {
	debugName = "Swim",
	environment = setmetatable({ Vector3 = Vector3 }, { __index = getfenv(1) }),
})()
local SeaMotion = luau.load(fs.readFile("src/client/Controllers/SeaMotion.luau"), {
	debugName = "SeaMotion",
	environment = setmetatable({ CFrame = CFrame, Vector3 = Vector3 }, { __index = getfenv(1) }),
})()

local SURFACE = Swim.Surface
local SEABED = -14 -- el fondo del mar (TerrainBuilder: arena hasta -14, agua de -14 a -2)

---------------------------------------------------------------------
print("▶ Las alturas del agua")
check(SURFACE == -2, "La superficie está a -2 (como Boats.SeaLevel y Fishing.Dive.Surface)")
do
	local boats = fs.readFile("src/shared/Boats.luau")
	local fishing = fs.readFile("src/shared/Fishing.luau")
	check(string.find(boats, "Boats.SeaLevel = -2", 1, true) ~= nil and string.find(fishing, "Surface = -2", 1, true) ~= nil, "Y los demás módulos dicen lo mismo")
end
check(not Swim.isUnderwater(Swim.floatY(1, 0), 1, false) and not Swim.isUnderwater(Swim.floatY(1, 1), 1, false), "Flotando quieto o nadando a crol: no estás bajo el agua")
check(not Swim.isUnderwater(Swim.floatY(1, 0), 1, true) and not Swim.isUnderwater(Swim.floatY(1, 1), 1, true), "…ni aunque vinieras de bucear (el margen no te deja 'bajo el agua' en la superficie)")
check(Swim.isUnderwater(SURFACE - 3, 1, false), "Tres studs más abajo, sí")
check(Swim.isUnderwater(SURFACE - 1.8, 1, true) and not Swim.isUnderwater(SURFACE - 1.8, 1, false), "Con margen: a 1,8 sigue lo que era (no cambia a cada segundo)")
check(Swim.floatY(1, 0) < SURFACE and Swim.floatY(1, 0) > SURFACE - 2, "Flotando quieto, el centro del cuerpo algo por debajo de la superficie (hombros en el agua, cabeza fuera)")
check(Swim.floatY(1, 1) > Swim.floatY(1, 0), "Nadando tumbado va más arriba (la espalda a ras de agua y la cabeza fuera)")
check(Swim.floatY(0.5, 0) > Swim.floatY(1, 0), "Un niño (más pequeño) flota más arriba")
check(not Swim.deepEnough(-5, 1) and Swim.deepEnough(SEABED, 1) and Swim.deepEnough(nil, 1), "En la orilla (3 studs de agua) se hace pie; en el mar (12) y en alta mar se nada")

---------------------------------------------------------------------
-- Simulación vertical: el cuerpo va hacia la velocidad que pide Swim.step con aceleración limitada
-- (como la LinearVelocity de Swimming), cada 1/60 s
local DT = 1 / 60
local function simulate(start: { Y: number, V: number?, Mode: string? }, seconds: number, input: number | (t: number) -> number, floor: number?, moving: number?)
	local y, v, mode = start.Y, start.V or 0, start.Mode or "Surface"
	local trace = {}
	local t = 0
	while t < seconds do
		local i = if type(input) == "function" then input(t) else input
		local vy
		mode, vy = Swim.step({ Mode = mode, RootY = y, FloorY = floor, Scale = 1, Input = i, Moving = moving or 0 })
		local dv = math.clamp(vy - v, -Swim.Accel * DT, Swim.Accel * DT)
		v += dv
		y += v * DT
		table.insert(trace, { T = t, Y = y, V = v, Mode = mode })
		t += DT
	end
	return y, v, mode, trace
end

print("\n▶ Flotar en la superficie")
do
	local y, v, mode, trace = simulate({ Y = Swim.floatY(1, 0) }, 6, 0, SEABED)
	local drift = 0
	for _, s in trace do
		drift = math.max(drift, math.abs(s.Y - Swim.floatY(1, 0)))
	end
	check(drift < 0.05 and mode == "Surface" and math.abs(v) < 0.05, ("Quieto flotando: se queda a su altura (se mueve %.3f studs)"):format(drift))
	-- Al caer al agua (desde el muelle o un barco): baja un poco, frena y vuelve a flotar sin rebotes
	y, v, mode, trace = simulate({ Y = SURFACE + 0.1, V = -35 }, 5, 0, SEABED)
	local lowest, crossings, last = math.huge, 0, nil
	for _, s in trace do
		lowest = math.min(lowest, s.Y)
		local sign = if s.Y > Swim.floatY(1, 0) + 0.3 then 1 elseif s.Y < Swim.floatY(1, 0) - 0.3 then -1 else 0
		if sign ~= 0 and last and sign ~= last then
			crossings += 1
		end
		if sign ~= 0 then
			last = sign
		end
	end
	check(lowest > SEABED + Swim.FloorClear - 0.05, ("Cayendo al agua a 35 studs/s: frena antes del fondo (baja hasta %.1f)"):format(lowest))
	check(math.abs(y - Swim.floatY(1, 0)) < 0.2 and mode == "Surface", "Y vuelve a flotar con la cabeza fuera")
	check(crossings <= 1, ("Sin rebotes arriba y abajo (%d)"):format(crossings))
	-- Nadando a crol (avanza): un poco más arriba, sin saltos
	y = simulate({ Y = Swim.floatY(1, 0) }, 3, 0, SEABED, 1)
	check(math.abs(y - Swim.floatY(1, 1)) < 0.1, "Nadando sube a ras de agua (espalda fuera)")
	-- Poco fondo (a 4,5 studs): no hay sitio para bucear, solo flotar
	y = simulate({ Y = Swim.floatY(1, 0) }, 3, -1, SURFACE - 4.5)
	check(y >= math.min(SURFACE - 4.5 + Swim.FloorClear, Swim.floatY(1, 0)) - 0.05, "Con poco fondo, Bucear no te tumba en la arena (como mucho, flotas)")
	local _, _, shallowMode = simulate({ Y = Swim.floatY(1, 0) }, 3, -1, SURFACE - 3.5)
	check(shallowMode == "Surface", "Y si no cabes buceando, solo flotas")
end

print("\n▶ Bucear y subir")
do
	-- Mantener Bucear 1 s
	local y, v, mode = simulate({ Y = Swim.floatY(1, 0) }, 1, -1, SEABED)
	check(mode == "Dive" and y < Swim.floatY(1, 0) - 5 and y > Swim.floatY(1, 0) - 10.5, ("Bucear 1 s baja de forma controlada (%.1f studs)"):format(Swim.floatY(1, 0) - y))
	-- Soltar: se queda a esa profundidad (flotabilidad neutra), sin subir de golpe
	local held = y
	local y2, _, mode2, trace = simulate({ Y = y, V = v, Mode = mode }, 4, 0, SEABED)
	local after = trace[60] -- 1 s después de soltar ya ha frenado
	local drift = 0
	for i = 60, #trace do
		drift = math.max(drift, math.abs(trace[i].Y - after.Y))
	end
	check(mode2 == "Dive" and math.abs(after.Y - held) < 1.2 and drift < 0.02, ("Al soltar se queda quieto a esa profundidad (frena en %.2f studs, luego %.3f)"):format(math.abs(after.Y - held), drift))
	check(Swim.isUnderwater(y2, 1, true), "Y ahí está bajo el agua (se gasta el aire)")
	-- Mantener Bucear mucho: nunca baja hasta tumbarse en el fondo
	local y3, _, _, trace3 = simulate({ Y = Swim.floatY(1, 0) }, 5, -1, SEABED)
	local lowest = math.huge
	for _, s in trace3 do
		lowest = math.min(lowest, s.Y)
	end
	check(lowest >= SEABED + Swim.FloorClear - 0.05, ("Con Bucear pulsado se para sobre el fondo (el centro del cuerpo a %.2f del fondo, no tumbado)"):format(lowest - SEABED))
	check(math.abs(y3 - (SEABED + Swim.FloorClear)) < 0.1, "Y se queda ahí, nadando sobre la arena")
	-- Soltar en el fondo: no se hunde ni se tumba
	local y4 = simulate({ Y = y3, Mode = "Dive" }, 5, 0, SEABED)
	check(y4 >= SEABED + Swim.FloorClear - 0.05, "Soltando en el fondo: se queda flotando encima, no se hunde")
	-- Subir: vuelve a la superficie y a flotar
	local y5, _, mode5 = simulate({ Y = y3, Mode = "Dive" }, 4, 1, SEABED)
	check(mode5 == "Surface" and math.abs(y5 - Swim.floatY(1, 0)) < 0.35, "Subir te lleva a la superficie y vuelves a flotar")
	check(not Swim.isUnderwater(y5, 1, true), "Arriba ya respiras")
	-- Alta mar (sin fondo cerca): igual de controlado
	local y6, _, mode6 = simulate({ Y = Swim.floatY(1, 0) }, 1, -1, nil)
	check(mode6 == "Dive" and y6 < SURFACE - 5, "En alta mar también se baja con Bucear")
	-- Subir en la superficie no te saca volando del agua
	local y7 = simulate({ Y = Swim.floatY(1, 0) }, 2, 1, SEABED)
	check(y7 < SURFACE, "Subir estando arriba no te saca del agua (para salir, Saltar)")
end

print("\n▶ En la orilla a 2 m (v122: captura del dueño andando por la arena)")
do
	-- 2 m bajo la superficie, quieto y sin tocar nada: se queda ahí nadando, sin bajar a la arena
	local start = SURFACE - 2 * 3.57
	local y, _, mode = simulate({ Y = start, Mode = "Dive" }, 4, 0, SEABED)
	check(mode == "Dive" and math.abs(y - start) < 0.1, ("A 2 m quieto: flotas ahí (%.2f studs de deriva)"):format(math.abs(y - start)))
	check(Swim.deepEnough(SEABED, 1) and not Swim.deepEnough(SURFACE - 3.5, 1), "En 3,4 m de agua se nada; solo en menos de ~1,2 m se hace pie")
	-- Bucear hasta el fondo: el centro del cuerpo se queda a FloorClear; los pies (~3 studs bajo la
	-- cadera de pie) no tocan la arena, así el Humanoid no se pone a andar
	local y2 = simulate({ Y = start, Mode = "Dive" }, 4, -1, SEABED)
	check(y2 - SEABED >= 3.4, ("Pegado al fondo, el cuerpo queda a %.1f studs de la arena: los pies no la tocan"):format(y2 - SEABED))
end

print("\n▶ El aire (DivingService.underwater usa Swim.isUnderwater con el centro del cuerpo)")
do
	-- Las reglas del servidor, cada segundo: bajo el agua −1; fuera +Refill
	local Fishing = fs.readFile("src/shared/Fishing.luau")
	local refill = tonumber(string.match(Fishing, "Refill = (%d+)")) or 10
	local oxygen, max = 20, 20
	local was = false
	local lowestAtSurface = max
	-- 20 s nadando en la superficie (quieto y avanzando: la postura no importa, se mira el centro)
	for s = 1, 20 do
		local y = Swim.floatY(1, if s % 2 == 0 then 1 else 0)
		was = Swim.isUnderwater(y, 1, was)
		oxygen = if was then math.max(0, oxygen - 1) else math.min(max, oxygen + refill)
		lowestAtSurface = math.min(lowestAtSurface, oxygen)
	end
	check(lowestAtSurface == max, "Nadando en la superficie el aire no baja (antes: 18 s, 20 s, 18 s…)")
	for _ = 1, 8 do
		was = Swim.isUnderwater(SURFACE - 6, 1, was)
		oxygen = if was then math.max(0, oxygen - 1) else math.min(max, oxygen + refill)
	end
	check(oxygen == max - 8, "Buceando 8 s se gastan 8 s de aire")
	was = Swim.isUnderwater(Swim.floatY(1, 0), 1, was)
	oxygen = if was then math.max(0, oxygen - 1) else math.min(max, oxygen + refill)
	check(not was and oxygen > max - 8, "Al salir a la superficie se recupera")
	local diving = fs.readFile("src/server/Services/DivingService.luau")
	check(string.find(diving, "Swim.isUnderwater(root.Position.Y", 1, true) ~= nil and string.find(diving, "headOf", 1, true) == nil, "El servidor mira el centro del cuerpo, no la cabeza")
end

---------------------------------------------------------------------
print("\n▶ La postura (SeaMotion): nunca boca abajo")
do
	local worstDown, worstUp, badPose = 1, -1, nil
	local function input(over)
		local i = { InWater = true, Underwater = false, Speed = 0, Vertical = 0, Armed = false, ShotAgo = math.huge, Fish = nil, FishAgo = 0, Phase = 0, Seed = 1 }
		for k, v in over do
			i[k] = v
		end
		return i
	end
	for _, under in { false, true } do
		for _, armed in { false, true } do
			for speed = 0, 20, 2 do
				for vertical = -30, 30, 3 do
					for t = 0, 3, 0.37 do
						local pose, state = SeaMotion.pose(input({ Underwater = under, Armed = armed, Speed = speed, Vertical = vertical, Phase = t * 4, ShotAgo = t }), t)
						local root = pose and pose.Root
						if root then
							-- El eje del tronco (arriba del cuerpo) nunca apunta hacia abajo más de ~30°
							local up = root.UpVector
							if up.Y < worstDown then
								worstDown = up.Y
								badPose = ("%s v=%d s=%d"):format(tostring(state), vertical, speed)
							end
							worstUp = math.max(worstUp, up.Y)
						end
					end
				end
			end
		end
	end
	check(worstDown > -0.5, ("El tronco nunca queda cabeza abajo (lo más: %.2f en %s)"):format(worstDown, tostring(badPose)))
	check(SeaMotion.bodyPitch(-30, 1) >= -math.pi / 2 - SeaMotion.MaxHeadDown - 1e-6, "Bajando rápido: de cabeza, pero como mucho " .. math.floor(math.deg(SeaMotion.MaxHeadDown)) .. "° bajo la horizontal")
	check(math.abs(SeaMotion.bodyPitch(0, 1) + math.pi / 2) < 1e-6, "Buceando recto hacia delante: horizontal")
	check(SeaMotion.bodyPitch(0, 0) > SeaMotion.bodyPitch(0, 1), "Quieto bajo el agua: más de pie")
	-- Crol en la superficie: horizontal (boca abajo), estable
	local crawl = SeaMotion.crawl(1, 1, 1)
	check(math.abs(crawl.Root.UpVector.Y) < 0.2, "Nadando a crol el cuerpo va horizontal")
	-- La velocidad vertical suavizada (AgeMotion.SeaV) no cambia de postura a cada frame: una
	-- velocidad que tiembla (+6/−6 cada frame, como la física a trozos) da siempre la misma postura
	local sv, states = 0, {}
	for f = 1, 120 do
		local raw = if f % 2 == 0 then 6 else -6
		sv += (raw - sv) * (1 - math.exp(-5 * DT))
		local _, state = SeaMotion.pose(input({ Underwater = true, Speed = 8, Vertical = sv }), f * DT)
		states[state] = true
	end
	local n = 0
	for _ in states do
		n += 1
	end
	check(n == 1, "Con la velocidad suavizada la postura no salta de bajar a subir")
	local age = fs.readFile("src/client/Controllers/AgeMotion.luau")
	check(string.find(age, "body.SeaV +=", 1, true) ~= nil and string.find(age, "Swim.isUnderwater(position.Y", 1, true) ~= nil, "AgeMotion suaviza la vertical y mira el centro del cuerpo")
end

---------------------------------------------------------------------
print("\n▶ v124: el tronco nunca cabeza abajo, aunque Roblox tumbe el HumanoidRootPart («nada al revés»)")
do
	-- El rig R15 de Roblox: Root (HumanoidRootPart → LowerTorso), C0 (0,-1,0), C1 (0,-0.2,0)
	local C0, C1 = CFrame.new(0, -1, 0), CFrame.new(0, -0.2, 0)
	local function input(over)
		local i = { InWater = true, Underwater = false, Speed = 0, Vertical = 0, Armed = false, ShotAgo = math.huge, Fish = nil, FishAgo = 0, Phase = 0, Seed = 1 }
		for k, v in over do
			i[k] = v
		end
		return i
	end
	-- Los estados de nadar: superficie quieto y a crol, bucear, bajar, subir, quieto (cerca del fondo y lejos), apuntar
	local cases = {
		{ "Flotando quieto", { Underwater = false, Speed = 0 } },
		{ "A crol", { Underwater = false, Speed = 14 } },
		{ "Buceando", { Underwater = true, Speed = 12 } },
		{ "Bajando", { Underwater = true, Speed = 6, Vertical = -15 } },
		{ "Bajando rápido", { Underwater = true, Speed = 0, Vertical = -30 } },
		{ "Subiendo", { Underwater = true, Speed = 4, Vertical = 15 } },
		{ "Quieto bajo el agua", { Underwater = true, Speed = 0 } },
		{ "Quieto junto al fondo (lo empuja FloorClear)", { Underwater = true, Speed = 0, Vertical = 3 } },
		{ "Apuntando", { Underwater = true, Armed = true, Speed = 0, ShotAgo = 0.1 } },
	}
	-- Cómo puede estar el HumanoidRootPart: derecho, o tumbado por el estado Swimming de Roblox (hacia
	-- delante, hacia atrás, de lado, del todo boca abajo) con cualquier rumbo
	local roots = {}
	for _, yaw in { 0, 1.3, -2.4 } do
		for _, tilt in { { 0, 0 }, { -math.pi / 2, 0 }, { -1.1, 0 }, { 0.8, 0 }, { 0, 0.9 }, { -math.pi / 2, 0.4 }, { -math.pi + 0.02, 0 } } do
			table.insert(roots, CFrame.Angles(0, yaw, 0) * CFrame.Angles(tilt[1], 0, tilt[2]))
		end
	end
	local worst, worstWhat = 1, ""
	local headingOk = true
	for _, case in cases do
		for t = 0, 2, 0.5 do
			local pose = SeaMotion.pose(input(case[2]), t)
			for _, root in roots do
				local T = SeaMotion.uprightRoot(root, C0, pose.Root)
				local torso = root * C0 * T * C1:Inverse()
				-- lo mismo que con el cuerpo derecho: la inclinación del tronco respecto a la vertical no
				-- depende de cómo esté girado el HumanoidRootPart (el rumbo aparte)
				local ideal = C0 * pose.Root * C1:Inverse()
				if math.abs(torso.UpVector.Y - ideal.UpVector.Y) > 0.01 then
					headingOk = false
				end
				-- y el rumbo se mantiene: el tronco mira hacia donde mira (o hacia donde apunta la cabeza
				-- del HumanoidRootPart si Roblox lo ha tumbado del todo)
				if torso.UpVector.Y < worst then
					worst = torso.UpVector.Y
					worstWhat = case[1]
				end
			end
		end
	end
	-- "arriba del tronco" (de los pies a la cabeza) nunca más de ~100° de la vertical
	check(worst > math.cos(math.rad(100)), ("En todos los estados la cabeza queda por encima de los pies o casi (peor: %.0f° de la vertical, %s)"):format(math.deg(math.acos(math.clamp(worst, -1, 1))), worstWhat))
	check(headingOk, "El tronco queda igual que con el HumanoidRootPart derecho, lo tumbe o no Roblox")
	-- Sin corrección (lo que pasaba): Roblox tumba 90° hacia delante + la postura de bucear = cabeza abajo
	local tumbled = CFrame.Angles(-math.pi / 2, 0, 0)
	local dive = SeaMotion.dive(0, 0, 1, -10, 1)
	check((tumbled * C0 * dive.Root * C1:Inverse()).UpVector.Y < -0.5, "(Comprobado: sin corregir, ese caso quedaba cabeza abajo)")
	check(SeaMotion.MaxHeadDown <= math.rad(10) + 1e-6, "Bajando, la cabeza como mucho 10° por debajo de la horizontal")
	local age = fs.readFile("src/client/Controllers/AgeMotion.luau")
	check(string.find(age, "SeaMotion.uprightRoot(body.Root.CFrame", 1, true) ~= nil, "AgeMotion corrige la postura con el giro real del HumanoidRootPart")
	local swimming = fs.readFile("src/client/Controllers/Swimming.luau")
	check(string.find(swimming, "upright.RigidityEnabled = true", 1, true) ~= nil, "Swimming mantiene el HumanoidRootPart derecho con una AlignOrientation rígida")
end

---------------------------------------------------------------------
print("\n▶ v125: R15 y R6, el Animator que reescribe Transform cada frame y lo que se VE")
do
	local HALF = math.pi / 2
	-- Los rigs de Roblox tal cual (C0/C1 de las articulaciones de serie)
	local R15 = {
		Root = { C0 = CFrame.new(0, -1, 0), C1 = CFrame.new(0, -0.2, 0) },
		RightShoulder = { C0 = CFrame.new(1, 0.56, 0), C1 = CFrame.new(-0.25, 0.4, 0) },
		RightHip = { C0 = CFrame.new(0.5, -0.2, 0), C1 = CFrame.new(0, 0.4, 0) },
		Neck = { C0 = CFrame.new(0, 0.8, 0), C1 = CFrame.new(0, -0.5, 0) },
	}
	local R6 = {
		Root = { C0 = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), C1 = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
		RightShoulder = { C0 = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), C1 = CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
		RightHip = { C0 = CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), C1 = CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
		Neck = { C0 = CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), C1 = CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
	}
	-- Con el cuerpo en reposo (Transform = identidad) la pieza de fuera queda derecha (comprobación del rig)
	for rigName, rig in { R15 = R15, R6 = R6 } do
		local torsoRest = rig.Root.C0 * rig.Root.C1:Inverse()
		check(torsoRest.UpVector.Y > 0.999 and torsoRest.LookVector.Z < -0.999, rigName .. ": en reposo el tronco está derecho y mirando a −Z (rig bien copiado)")
	end
	local dive = SeaMotion.dive(0, 0, 1, 0, 1)
	local function torsoOf(rig, root, T)
		return root * rig.Root.C0 * T * rig.Root.C1:Inverse()
	end
	-- La cuenta de antes (Transform = giro tal cual) con R6: tumbaba el cuerpo HACIA ATRÁS
	local naive6 = torsoOf(R6, CFrame.identity, dive.Root)
	check(naive6.LookVector.Y > 0.9, "(Comprobado: en R6, poner el giro de R15 tal cual en RootJoint deja la tripa ARRIBA —boca arriba—)")
	for rigName, rig in { R15 = R15, R6 = R6 } do
		for _, yaw in { 0, 2.2 } do
			local root = CFrame.Angles(0, yaw, 0)
			local T = SeaMotion.uprightRoot(root, rig.Root.C0, dive.Root)
			local torso = torsoOf(rig, root, T)
			local heading = root.LookVector
			check(torso.LookVector.Y < -0.9 and torso.UpVector:Dot(heading) > 0.9 and not SeaMotion.inverted(torso),
				("%s (rumbo %.1f): buceando, tripa ABAJO y la cabeza hacia donde nada"):format(rigName, yaw))
		end
		-- El brazo derecho estirado delante de la cabeza (braza): el brazo apunta a donde nada
		local arm = dive.RightShoulder
		local T = SeaMotion.uprightRoot(CFrame.identity, rig.Root.C0, dive.Root)
		local torso = torsoOf(rig, CFrame.identity, T)
		local Ta = SeaMotion.toJoint(rig.RightShoulder.C0, arm)
		local armCf = torso * rig.RightShoulder.C0 * Ta * rig.RightShoulder.C1:Inverse()
		local ideal = torso * arm * rig.RightShoulder.C0 * rig.RightShoulder.C1:Inverse() -- (el giro en los ejes del tronco)
		check(armCf.UpVector:Dot(ideal.UpVector) > 0.999, rigName .. ": el hombro gira sobre el eje de los hombros (toJoint)")
	end
	-- Lo que pasa en Roblox cada frame: el Animator ESCRIBE Transform (la animación «swim» de serie) en
	-- PreAnimation; AgeMotion lo sobrescribe en PreSimulation; LUEGO la física. Si el estado Swimming
	-- de Roblox tumba el HumanoidRootPart durante la física, la cuenta se hizo con el giro viejo.
	local PoseLayers = luau.load(fs.readFile("src/client/Controllers/PoseLayers.luau"), { debugName = "PoseLayers", environment = setmetatable({ CFrame = CFrame }, { __index = getfenv(1) }) })()
	local function run(rig, humanoidTilts: boolean)
		PoseLayers.reset()
		local joint = { Transform = CFrame.identity }
		local root = CFrame.identity
		local flip, safeUntil, fixes, seenInverted, lateInverted = 0, -1, 0, 0, 0
		local torso = torsoOf(rig, root, CFrame.identity)
		PoseLayers.add("AgeMotion", 10, function(dt, t)
			local pose = SeaMotion.dive(t * 3, t, 1, 0, 1)
			if SeaMotion.inverted(torso) then
				flip += dt
			else
				flip = math.max(0, flip - dt * 0.5)
			end
			if flip > 0.25 and t >= safeUntil then
				safeUntil, flip, fixes = t + 8, 0, fixes + 1
			end
			local safe = t < safeUntil
			local target = if safe then SeaMotion.safe(pose) else pose
			PoseLayers.write(joint, if safe then SeaMotion.toJoint(rig.Root.C0, target.Root) else SeaMotion.uprightRoot(root, rig.Root.C0, target.Root))
		end)
		for frame = 1, 120 do
			local t = frame / 60
			-- PreAnimation: el Animator reescribe Transform (aquí: una «swim» de serie que ya tumba 80°)
			joint.Transform = CFrame.Angles(-1.4 + 0.05 * math.sin(t * 9), 0, 0)
			PoseLayers.step(1 / 60, t)
			-- Física: con el estado Swimming encendido, Roblox tumba el HumanoidRootPart 90° hacia delante
			-- un frame sí y otro no (pelea con la AlignOrientation)
			root = if humanoidTilts and frame % 2 == 0 then CFrame.Angles(-HALF, 0, 0) else CFrame.identity
			torso = torsoOf(rig, root, joint.Transform)
			if SeaMotion.inverted(torso) then
				seenInverted += 1
				if frame > 90 then
					lateInverted += 1
				end
			end
		end
		return seenInverted, fixes, lateInverted
	end
	for rigName, rig in { R15 = R15, R6 = R6 } do
		local bad = run(rig, false)
		check(bad == 0, ("%s, con el Animator reescribiendo Transform y Swimming apagado (HumanoidRootPart derecho): 0 frames al revés de 120 (%d)"):format(rigName, bad))
		local badTilt, fixes, late = run(rig, true)
		check(fixes >= 1 and late == 0, ("%s, si Roblox tumbara igualmente el cuerpo (%d frames al revés): la medida lo ve, pone la postura de seguridad (%d vez) y en el último medio segundo 0 frames al revés (%d)"):format(rigName, badTilt, fixes, late))
	end
	local age = fs.readFile("src/client/Controllers/AgeMotion.luau")
	check(string.find(age, "SeaMotion.inverted(torso.CFrame)", 1, true) ~= nil and string.find(age, "SeaMotion.safe(seaTarget)", 1, true) ~= nil, "AgeMotion mide el tronco ya dibujado y pasa a la postura de seguridad si se ve al revés")
	check(string.find(age, "SeaMotion.toJoint(Joints.c0(joint), cf)", 1, true) ~= nil and string.find(age, "HumanoidRigType.R6", 1, true) ~= nil, "AgeMotion también mueve los R6 (con toJoint) al nadar")
	local loco = fs.readFile("src/client/Controllers/Locomotion.luau")
	check(string.find(loco, 'GetAttribute("SwimMode")', 1, true) ~= nil, "Locomotion no inclina ni gira el cuerpo nadando (el Humanoid va en Freefall)")
end

---------------------------------------------------------------------
print("\n▶ La cámara")
do
	local focus = Vector3.new(0, SEABED + 3, 0)
	local cam = Vector3.new(0, SEABED - 2, 12)
	local fixed = Swim.cameraPosition(cam, focus, SEABED)
	check(fixed.Y >= SEABED + Swim.CameraClear - 1e-4, ("Cámara dentro de la arena → sale por encima del fondo (%.2f)"):format(fixed.Y))
	local a, b = (focus - cam).Unit, (focus - fixed).Unit
	check(a:Dot(b) > 0.9999, "Y sigue en la misma línea (sigue mirando al personaje)")
	check(Swim.cameraPosition(Vector3.new(0, -5, 10), focus, SEABED) == Vector3.new(0, -5, 10), "Si ya está por encima del fondo no se toca")
	local low = Swim.cameraPosition(Vector3.new(0, SEABED - 3, 5), Vector3.new(0, SEABED + 0.5, 0), SEABED)
	check(low.Y >= SEABED + Swim.CameraClear - 1e-4, "Aunque el personaje esté muy abajo, la cámara no se mete en la arena")
	check(Swim.cameraY(SURFACE - 0.1, "Surface") >= SURFACE + Swim.CameraBand and Swim.cameraY(SURFACE + 4, "Surface") == SURFACE + 4, "Flotando, la cámara va por encima del agua")
	local d = Swim.cameraY(SURFACE + 0.1, "Dive")
	check(math.abs(d - SURFACE) >= Swim.CameraBand - 1e-6 and Swim.cameraY(SURFACE - 5, "Dive") == SURFACE - 5, "Buceando no se queda partida en la superficie")
end

---------------------------------------------------------------------
-- Controllers/Swimming con un Roblox de mentira: el personaje en el mar, la física simple
print("\n▶ El control del cuerpo (Controllers/Swimming)")
do
	local function signal()
		local list = {}
		return {
			Connect = function(_, f)
				table.insert(list, f)
				return { Disconnect = function() end }
			end,
			Fire = function(_, ...)
				for _, f in list do
					f(...)
				end
			end,
		}
	end
	local attrs = {}
	local root = {
		Name = "HumanoidRootPart",
		Position = Vector3.new(0, SURFACE + 3, 0),
		AssemblyLinearVelocity = Vector3.zero,
		AssemblyMass = 10,
		Anchored = false,
	}
	local state = Enum.HumanoidStateType.Freefall
	local humanoid = { Health = 100, SeatPart = nil, Sit = false, PlatformStand = false, Jump = false }
	function humanoid.GetState()
		return state
	end
	-- (v125) El estado Swimming de Roblox se puede apagar; ChangeState lo cambia como en Roblox
	local enabledStates = {}
	local jumpsAsked = 0
	function humanoid.SetStateEnabled(_, st, on)
		enabledStates[tostring(st)] = on
	end
	function humanoid.ChangeState(_, st)
		if st == Enum.HumanoidStateType.Jumping then
			jumpsAsked += 1
		end
		state = st
	end
	local character = {}
	function character.GetScale()
		return 1
	end
	function character.FindFirstChildOfClass(_, class)
		return if class == "Humanoid" then humanoid else nil
	end
	function character.FindFirstChild(_, name)
		return if name == "HumanoidRootPart" then root else nil
	end
	local player = { Character = character, CharacterAdded = signal() }
	function player.GetAttribute(_, k)
		return attrs[k]
	end
	function player.SetAttribute(_, k, v)
		attrs[k] = v
	end
	local created = {}
	local inDome = false -- (Nácara: ¿dentro de la cúpula de aire?)
	local heartbeat = signal()
	local renderSteps = {}
	local camera = { CameraType = Enum.CameraType.Custom, CFrame = CFrame.new(0, SEABED - 1, 10), Focus = CFrame.new(0, SEABED + 3, 0) }
	local seabed = SEABED
	local fakeWorkspace = { Terrain = {}, CurrentCamera = camera, Gravity = 196.2 }
	function fakeWorkspace.Raycast(_, origin, direction, params)
		if math.abs(origin.X) > 500 then
			return nil -- tierra firme, sin agua
		end
		if params.IgnoreWater then
			if origin.Y >= seabed and origin.Y + direction.Y <= seabed then
				return { Position = Vector3.new(origin.X, seabed, origin.Z), Material = Enum.Material.Sand }
			end
			return nil
		end
		return { Position = Vector3.new(origin.X, SURFACE, origin.Z), Material = Enum.Material.Water }
	end
	local services = {
		Players = { LocalPlayer = player },
		ReplicatedStorage = { Shared = { Swim = "Swim", Sea = { Ocean = "Ocean", Nacara = "Nacara", MerForm = "MerForm" } } },
		RunService = {
			Heartbeat = heartbeat,
			BindToRenderStep = function(_, name, _, f)
				renderSteps[name] = f
			end,
		},
	}
	local env = {
		CFrame = CFrame,
		Vector3 = Vector3,
		Enum = Enum,
		workspace = fakeWorkspace,
		script = { Parent = {} },
		game = { GetService = function(_, name)
			return services[name]
		end },
		require = function(what)
			assert(what == "Swim" or what == "Ocean" or what == "Nacara" or what == "MerForm", "Swimming solo debería pedir Shared/Swim, Shared/Sea/Ocean, Shared/Sea/Nacara y Shared/Sea/MerForm: " .. tostring(what))
			if what == "MerForm" then
				-- (las reglas puras del nado con cola de los Hondarios)
				return luau.load(fs.readFile("src/shared/Sea/MerForm.luau"), { debugName = "MerForm" })()
			end
			if what == "Nacara" then
				-- (la cúpula de aire de Nácara: dentro se anda; la corriente guía, aquí quieta)
				return {
					inDome = function()
						return inDome
					end,
					currentAt = function()
						return Vector3.new(0, 0, 0)
					end,
				}
			end
			if what == "Ocean" then
				-- (las corrientes del mar hondo: aquí, agua quieta)
				return { currentAt = function()
					return Vector3.new(0, 0, 0)
				end }
			end
			return Swim
		end,
		RaycastParams = { new = function()
			return {}
		end },
		Instance = { new = function(class)
			local obj = { ClassName = class, Event = nil }
			if class == "BindableEvent" then
				local s = signal()
				obj.Event = s
				obj.Fire = function(_, ...)
					s:Fire(...)
				end
			end
			table.insert(created, obj)
			return obj
		end },
		warn = function(...)
			failures += 1
			print("  ❌ warn:", ...)
		end,
	}
	local engagedMax: number? = nil
	local Swimming
	Swimming = luau.load(fs.readFile("src/client/Controllers/Swimming.luau"), { debugName = "Swimming", environment = setmetatable(env, { __index = getfenv(1) }) })()
	Swimming.init()
	local function find(class)
		for _, o in created do
			if o.ClassName == class then
				return o
			end
		end
		return nil
	end
	-- Física de mentira: con la flotación encendida la velocidad va hacia la pedida con la fuerza que
	-- tiene; sin ella, la gravedad y (en el agua) una flotación de Roblox que te sube
	local function tick(n)
		for _ = 1, n do
			heartbeat:Fire(DT)
			local lift = find("LinearVelocity")
			local v = root.AssemblyLinearVelocity
			local vy = v.Y
			if lift and lift.Enabled then
				local accel = lift.MaxForce / root.AssemblyMass - fakeWorkspace.Gravity
				vy += math.clamp(lift.LineVelocity - vy, -accel * DT, accel * DT)
			elseif root.Position.Y < SURFACE then
				vy += (-(root.Position.Y - (SURFACE - 1)) * 20 - vy * 2) * DT
			else
				vy -= fakeWorkspace.Gravity * DT
			end
			root.AssemblyLinearVelocity = Vector3.new(v.X, vy, v.Z)
			root.Position += Vector3.new(0, vy * DT, 0)
			if root.Position.Y < seabed + 1 then
				root.Position = Vector3.new(root.Position.X, seabed + 1, root.Position.Z)
			end
			-- Roblox: en el agua pasa a Swimming… salvo que se haya apagado (entonces cae en Freefall)
			if root.Position.Y < SURFACE then
				state = if enabledStates[tostring(Enum.HumanoidStateType.Swimming)] == false then Enum.HumanoidStateType.Freefall else Enum.HumanoidStateType.Swimming
			end
			if engagedMax ~= nil and Swimming.isSwimming() and state == Enum.HumanoidStateType.Swimming then
				engagedMax += 1 -- frames nadando con el estado Swimming de Roblox encendido (no debe pasar)
			end
		end
	end
	engagedMax = 0
	tick(10)
	check(not Swimming.isSwimming() and attrs.SwimMode == nil, "Fuera del agua no hace nada")
	-- Se tira al agua (desde el muelle)
	root.AssemblyLinearVelocity = Vector3.new(0, -30, 0)
	tick(240)
	local lift, upright = find("LinearVelocity"), find("AlignOrientation")
	check(Swimming.isSwimming() and attrs.SwimMode == "Surface", "Al caer al agua empieza a nadar (SwimMode = Surface)")
	check(lift and lift.Enabled and lift.VelocityConstraintMode == Enum.VelocityConstraintMode.Line and lift.LineDirection == Vector3.yAxis, "La flotación (LinearVelocity) solo en vertical: avanzar sigue siendo de Roblox")
	check(math.abs(root.Position.Y - Swim.floatY(1, 0)) < 0.25, ("Y queda flotando con la cabeza fuera (%.2f)"):format(root.Position.Y))
	local att = find("Attachment")
	check(enabledStates[tostring(Enum.HumanoidStateType.Swimming)] == false and state ~= Enum.HumanoidStateType.Swimming, "v125: nadando, el estado Swimming de Roblox está APAGADO (un solo dueño del giro: no tumba el HumanoidRootPart)")
	check(engagedMax <= 1, ("v125: como mucho 1 frame con el control puesto y el estado Swimming de Roblox a la vez (%d)"):format(engagedMax))
	check(upright and upright.Enabled and upright.PrimaryAxisOnly and upright.PrimaryAxis == Vector3.yAxis and att and att.CFrame.XVector:Dot(Vector3.yAxis) > 0.999, "El cuerpo va derecho (AlignOrientation solo endereza: ni vueltas ni de lado; girar sigue libre)")
	-- La cámara, dentro de la arena → fuera; flotando, por encima del agua
	camera.CFrame = CFrame.new(0, SEABED - 1, 10)
	camera.Focus = CFrame.new(root.Position)
	renderSteps.SwimCamera()
	check(camera.CFrame.Position.Y >= SURFACE + Swim.CameraBand - 1e-3, ("Cámara metida en el fondo → sale (a %.2f), y flotando va por encima del agua"):format(camera.CFrame.Position.Y))
	-- Bucear
	Swimming.setInput(-1)
	tick(180)
	check(attrs.SwimMode == "Dive" and root.Position.Y >= SEABED + Swim.FloorClear - 0.1, ("Bucear: baja y se para sobre el fondo (a %.2f de la arena)"):format(root.Position.Y - SEABED))
	camera.CFrame = CFrame.new(0, SEABED - 2, 8)
	camera.Focus = CFrame.new(root.Position)
	renderSteps.SwimCamera()
	check(camera.CFrame.Position.Y >= SEABED + Swim.CameraClear - 1e-3, "Buceando junto al fondo, la cámara no se mete en la arena")
	Swimming.setInput(0)
	tick(30)
	local held = root.Position.Y
	tick(180)
	check(math.abs(root.Position.Y - held) < 0.05 and attrs.SwimMode == "Dive", "Soltando: se queda a esa profundidad (no sube de golpe ni se tumba)")
	-- Espacio (buceando): sube
	Swimming.setJump(true)
	tick(180)
	Swimming.setJump(false)
	check(attrs.SwimMode == "Surface" and math.abs(root.Position.Y - Swim.floatY(1, 0)) < 0.4, "Espacio (o Subir) te lleva a la superficie")
	-- Saltar en la superficie (al muelle): sin el estado Swimming Roblox no salta solo → se pide
	humanoid.Jump = true
	tick(2)
	humanoid.Jump = false
	check(jumpsAsked >= 1, "v125: Saltar flotando pide el salto a Roblox (ChangeState Jumping), aunque Swimming esté apagado")
	tick(60)
	-- En la orilla (se hace pie): se apaga, andas por el fondo
	seabed = SURFACE - 3
	root.Position = Vector3.new(0, seabed + 2.5, 0)
	tick(20)
	check(not Swimming.isSwimming() and not lift.Enabled and not upright.Enabled and attrs.SwimMode == nil, "Donde se hace pie no se nada: se anda por el fondo")
	check(enabledStates[tostring(Enum.HumanoidStateType.Swimming)] == true, "v125: al dejar de nadar, el estado Swimming de Roblox se vuelve a encender")
	-- Sentado en un barco o muerto: nada
	seabed = SEABED
	root.Position = Vector3.new(0, SURFACE - 1, 0)
	humanoid.SeatPart = {}
	tick(20)
	check(not Swimming.isSwimming(), "Sentado (en un barco, un flotador…) no se nada")
	humanoid.SeatPart = nil
	tick(20)
	check(Swimming.isSwimming(), "Y al levantarse en el agua, sí")
	-- En la cúpula de aire de Nácara (terreno de Aire, suelo seco): se anda, no se nada
	inDome = true
	tick(20)
	check(not Swimming.isSwimming() and attrs.SwimMode == nil and not lift.Enabled, "Dentro de la cúpula de aire de Nácara no se nada: se anda por el suelo seco")
	inDome = false
	tick(20)
	check(Swimming.isSwimming(), "Y al salir de la cúpula al agua, otra vez nadando")
end

---------------------------------------------------------------------
print("\n▶ Los botones (móvil)")
do
	local combat = fs.readFile("src/client/Controllers/CombatController.luau")
	local weapons = fs.readFile("src/client/Controllers/WeaponController.luau")
	local missing = {}
	for id in string.gmatch(combat .. weapons, 'Id = "(%a+)", Icon = "%a+", Label = "%a+", Slot') do
		if not Swim.HiddenButtons[id] then
			table.insert(missing, id)
		end
	end
	check(#missing == 0, "Nadando se esconden todos los botones de pelear y de armas" .. (if #missing > 0 then ": faltan " .. table.concat(missing, ", ") else ""))
	check(Swim.HiddenButtons.Gestos and Swim.HiddenButtons.Agacharse and not Swim.HiddenButtons.Saltar and not Swim.HiddenButtons.Interactuar and not Swim.HiddenButtons.Correr, "…también gestos y agacharse; Saltar, Correr e Interactuar se quedan")
	local diving = fs.readFile("src/client/Controllers/DivingUI.luau")
	check(string.find(diving, 'Label = "Bucear", Slot = "Ataque"', 1, true) ~= nil and string.find(diving, 'Label = "Subir", Slot = "Defender"', 1, true) ~= nil, "Bucear va en el hueco grande y Subir al lado (los de pelear, libres)")
	check(string.find(diving, "TouchLayout.setSwimming(swimming, Swim.HiddenButtons)", 1, true) ~= nil, "DivingUI avisa al racimo cuando nadas")
	check(string.find(diving, "AssemblyLinearVelocity =", 1, true) == nil, "DivingUI ya no pisa la velocidad a mano (lo hace Swimming con la física)")
	-- (el cambio de botones en el racimo de verdad se prueba en scripts/test-hud.luau)
end

print(if failures == 0 then "\n✅ Nadar y bucear: todo bien" else ("\n❌ %d fallos"):format(failures))
process.exit(if failures == 0 then 0 else 1)
