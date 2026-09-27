-- Prueba del gimnasio FUERA de Roblox, con Lune: las reglas (Shared/Gym) y las posturas de cada
-- ejercicio (Controllers/GymPoses).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-gym.luau
--
-- Comprueba que:
--   * hay al menos 10 máquinas distintas y todas están bien descritas
--   * la entrada del día y el abono mensual valen lo que dicen, se suman y caducan; los niños pagan
--     la mitad; los bebés no entrenan y los niños solo en las máquinas ligeras
--   * el ritmo (marcador y zona verde), lo que sube cada serie y la pérdida suave sin entrenar
--   * la Fuerza ensancha el cuerpo hasta +25 % (y se multiplica con el tamaño de la edad)
--   * las posturas dan números normales en todo el ciclo, empiezan y acaban igual (sin tirones al
--     repetir) y la mezcla entra y sale desde 0
--   * con un R15 de medidas normales (y de niño): sentado queda sobre el asiento, tumbado sobre el
--     banco, en la sentadilla los pies no se mueven del suelo y en las dominadas las manos llegan a la barra

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Color3, Enum = roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum

local Gym = luau.load(fs.readFile("src/shared/Gym.luau"), { debugName = "Gym" })()
local Combat = luau.load(fs.readFile("src/shared/Combat.luau"), { debugName = "Combat" })()
local env = setmetatable({ CFrame = CFrame, Vector3 = Vector3, Color3 = Color3, Enum = Enum }, { __index = getfenv(1) })
local GymPoses = luau.load(fs.readFile("src/client/Controllers/GymPoses.luau"), { debugName = "GymPoses", environment = env })()

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function near(a: number, b: number, tol: number?): boolean
	return math.abs(a - b) <= (tol or 1e-6)
end

---------------------------------------------------------------------
print("▶ Máquinas")
local count = 0
local wellDescribed = true
for _, kind in Gym.MachineOrder do
	local m = Gym.Machines[kind]
	count += 1
	if not m or m.Kind ~= kind or m.Name == "" or m.Icon == "" or m.Tempo <= 0 or m.Zone <= 0 or m.Zone >= 1 or m.Effort <= 0 or m.Gain <= 0
		or not (m.Stat == "Fuerza" or m.Stat == "Cardio" or m.Stat == "Mixto") then
		wellDescribed = false
		print("     ", kind)
	end
	if not GymPoses.get(kind) then
		wellDescribed = false
		print("      sin postura:", kind)
	end
end
check(count >= 10, ("hay %d máquinas (al menos 10)"):format(count))
check(wellDescribed, "todas tienen nombre, icono, ritmo, esfuerzo, ganancia y postura")
for _, kind in { "Cinta", "Bici", "Eliptica", "Remo", "PressBanca", "PressHombros", "Jalon", "Prensa", "Sentadilla", "Mancuernas", "Dominadas", "Saco", "Abdominales", "Comba" } do
	if not Gym.Machines[kind] then
		check(false, "falta la máquina " .. kind)
	end
end
check(Gym.Machines.Saco ~= nil and Gym.Machines.Yoga ~= nil and Gym.Machines.Comba ~= nil, "cinta, bici, elíptica, remo, pesas, poleas, prensa, rack, mancuernas, dominadas, saco, esterillas y comba")

---------------------------------------------------------------------
print("▶ Entrada, abono y edades")
local DAY = Gym.daySeconds(20)
check(DAY == 1200, "un día de juego dura 20 minutos reales")
check(Gym.price("Dia", "Adulto") == 5, "la entrada del día cuesta 5 €")
check(Gym.price("Mes", "Adulto") == 60, "el abono mensual cuesta 60 €")
check(Gym.price("Dia", "Nino") == 3 and Gym.price("Mes", "Nino") == 30, "los niños pagan la mitad (redondeando)")
check(Gym.price("Nada", "Adulto") == nil, "un abono que no existe no tiene precio")
local now = 1000000
local g = { PassUntil = 0 }
check(not Gym.hasAccess(g, now), "sin entrada no se puede entrenar")
check(not Gym.hasAccess(nil, now), "sin datos tampoco")
g.PassUntil = Gym.extend(g.PassUntil, "Dia", now, DAY)
check(Gym.hasAccess(g, now) and Gym.hasAccess(g, now + DAY - 1), "la entrada vale todo el día de juego")
check(not Gym.hasAccess(g, now + DAY), "y al día siguiente ya no")
check(Gym.daysLeft(g.PassUntil, now, DAY) == 1, "te queda 1 día")
g.PassUntil = Gym.extend(g.PassUntil, "Mes", now + 100, DAY)
check(g.PassUntil == now + DAY + 28 * DAY, "el abono se suma a lo que te quedaba (no se pierde)")
check(Gym.daysLeft(g.PassUntil, now, DAY) == 29, "29 días de gimnasio")
local expired = Gym.extend(now - 5000, "Mes", now, DAY)
check(expired == now + 28 * DAY, "si ya había caducado, el abono empieza hoy")
check(Gym.daysLeft(0, now, DAY) == 0, "sin abono quedan 0 días")
local okBaby = Gym.canUse("Cinta", "Bebe")
check(not okBaby, "un bebé no puede entrenar")
local anyBaby = false
for kind in Gym.Machines do
	if Gym.canUse(kind, "Bebe") then
		anyBaby = true
	end
end
check(not anyBaby, "en ninguna máquina")
check(Gym.canUse("Cinta", "Nino") and Gym.canUse("Comba", "Nino") and Gym.canUse("Abdominales", "Nino"), "un niño puede usar la cinta, la comba y las esterillas")
local okKid, why = Gym.canUse("PressBanca", "Nino")
check(not okKid and type(why) == "string", "pero no el press de banca (y se le explica)")
check(not Gym.canUse("Dominadas", "Nino") and not Gym.canUse("Sentadilla", "Nino"), "ni las dominadas ni la sentadilla con barra")
local allTeen = true
for kind in Gym.Machines do
	if not Gym.canUse(kind, "Adolescente") or not Gym.canUse(kind, "Mayor") then
		allTeen = false
	end
end
check(allTeen, "desde adolescente, todas las máquinas")
check(not Gym.canUse("Inventada", "Adulto"), "una máquina que no existe no se puede usar")

---------------------------------------------------------------------
print("▶ Ritmo")
local inRange = true
for i = 0, 200 do
	local p = Gym.cursor(i * 0.037, 1.3)
	if p < 0 or p > 1 then
		inRange = false
	end
end
check(inRange, "el marcador siempre está dentro de la barra")
check(near(Gym.cursor(0, 1.3), 0) and near(Gym.cursor(0.65, 1.3), 1) and near(Gym.cursor(1.3, 1.3), 0, 1e-9), "va de un extremo al otro y vuelve")
check(Gym.judge(0.5, 0.24) == "Perfecto", "en el centro: ¡perfecto!")
check(Gym.judge(0.5 + 0.1, 0.24) == "Bien", "dentro de la zona: bien")
check(Gym.judge(0.95, 0.24) == "Fallo" and Gym.judge(0.05, 0.24) == "Fallo", "fuera de la zona: fallo")
check(Gym.minRepGap("Sentadilla") > 0.5, "no se pueden hacer repeticiones a lo loco")

---------------------------------------------------------------------
print("▶ Progreso")
local d0 = Gym.gain(1.3, 0)
local d50 = Gym.gain(1.3, 50)
local d95 = Gym.gain(1.3, 95)
check(d0 > d50 and d50 > d95 and d95 > 0, "cuanto más fuerte, más cuesta subir (pero siempre se sube algo)")
check(Gym.gain(5, 99.9) <= 0.1 + 1e-9, "nunca se pasa de 100")
local s1, c1 = Gym.setGains("PressBanca", 0, 0)
check(s1 > 0 and c1 == 0, "el press de banca sube la Fuerza")
local s2, c2 = Gym.setGains("Cinta", 0, 0)
check(s2 == 0 and c2 > 0, "la cinta sube la Forma física")
local s3, c3 = Gym.setGains("Remo", 0, 0)
check(s3 > 0 and c3 > 0 and s3 > c3, "el remo y el saco suben las dos (más Fuerza)")
local s4 = Gym.setGains("PressBanca", 0, 0, Gym.PerfectBonus)
check(s4 > s1, "con todo perfecto se sube más")
check(select(1, Gym.setGains("Nada", 0, 0)) == 0, "una máquina que no existe no da nada")
-- ¿Cuántas series para llegar a 100? (que se pueda, pero cueste)
local strength, sets = 0, 0
while strength < 99 and sets < 5000 do
	strength += (Gym.setGains("Sentadilla", strength, 0))
	sets += 1
end
check(sets > 150 and sets < 1500, ("llegar a casi 100 de Fuerza cuesta %d series"):format(sets))

print("▶ Sin entrenar")
check(Gym.decayed(50, 0) == 50 and Gym.decayed(50, Gym.DecayGraceDays) == 50, "los primeros días no se pierde nada")
check(Gym.decayed(50, Gym.DecayGraceDays + 1) < 50 and Gym.decayed(50, Gym.DecayGraceDays + 1) > 48.5, "después, un poquito cada día")
check(Gym.decayed(50, 30) > 25, "ni en un mes sin ir se pierde la mitad")
check(Gym.decayed(0, 100) == 0 and Gym.decayed(-3, 10) == 0, "nunca baja de 0")
check(Gym.pendingDecayDays(0, now, DAY, 0) == 0, "si nunca has entrenado, no hay nada que perder")
check(Gym.pendingDecayDays(now, now + DAY * 2, DAY, 0) == 0, "a los 2 días, nada")
check(Gym.pendingDecayDays(now, now + DAY * 6, DAY, 0) == 3, "a los 6 días, 3 días de pérdida")
check(Gym.pendingDecayDays(now, now + DAY * 6, DAY, 3) == 0, "lo ya aplicado no se vuelve a quitar")
-- Aplicarlo en varias veces da lo mismo que de golpe
local once = Gym.decayed(80, 10)
local stepwise = 80
local applied = 0
for day = 1, 10 do
	local pending = Gym.pendingDecayDays(now, now + day * DAY, DAY, applied)
	if pending > 0 then
		stepwise = Gym.decayed(stepwise, pending + Gym.DecayGraceDays)
		applied += pending
	end
end
check(near(once, stepwise, 1e-6), "perderlo día a día o de golpe da lo mismo")

---------------------------------------------------------------------
print("▶ Cuerpo")
local w0, dd0 = Gym.bodyScale(0)
local w100, dd100 = Gym.bodyScale(100)
check(w0 == 1 and dd0 == 1, "sin entrenar, el cuerpo de siempre")
check(near(w100, 1.25) and near(dd100, 1.25), "a 100 de Fuerza: +25 % de ancho y de fondo")
check(select(1, Gym.bodyScale(500)) == w100 and select(1, Gym.bodyScale(-20)) == 1 and select(1, Gym.bodyScale(nil)) == 1, "no se pasa ni con valores raros")
local growing = true
local last = 1
for s = 0, 100, 5 do
	local w = Gym.bodyScale(s)
	if w < last then
		growing = false
	end
	last = w
end
check(growing, "cuanto más fuerte, más ancho")
local w50 = Gym.bodyScale(50)
check(w50 > 1.1 and w50 < 1.2, "a mitad de camino ya se nota")
check(near(0.65 * w100, 0.8125), "se multiplica con el tamaño de la edad (niño 0,65 × 1,25)")
check(Gym.punchMultiplier(100) == 1.2 and Gym.punchMultiplier(0) == 1, "pega hasta un 20 % más fuerte")
check(Combat.damage(1, 0, false) == 8 and Combat.damage(1, 0, false, 0) == 8, "sin músculo, el golpe de siempre")
check(Combat.damage(3, 0, false, 100) == 18, "con 100 de Fuerza del gimnasio el golpe fuerte quita 18 (15 + 20 %)")
check(Gym.level(0) == "principiante" and Gym.level(90) == "de competición", "nombres de nivel para la ficha")

---------------------------------------------------------------------
print("▶ Posturas")
-- Un R15 normal (tamaño 1): el mismo que usan test-agemotion y test-workanim
local function rig(scale: number)
	local function v(x, y, z)
		return Vector3.new(x, y, z) * scale
	end
	local function c(x, y, z)
		return CFrame.new(x * scale, y * scale, z * scale)
	end
	return {
		Sizes = {
			LowerTorso = v(2, 0.4, 1), UpperTorso = v(2, 1.6, 1), Head = v(1.2, 1.2, 1.2),
			RightUpperArm = v(1, 1.169, 1), RightLowerArm = v(1, 1.052, 1), RightHand = v(1, 0.3, 1),
			LeftUpperArm = v(1, 1.169, 1), LeftLowerArm = v(1, 1.052, 1), LeftHand = v(1, 0.3, 1),
			RightUpperLeg = v(1, 1.217, 1), RightLowerLeg = v(1, 1.193, 1), RightFoot = v(1, 0.3, 1),
			LeftUpperLeg = v(1, 1.217, 1), LeftLowerLeg = v(1, 1.193, 1), LeftFoot = v(1, 0.3, 1),
		},
		Joints = {
			Root = { Part0 = "HumanoidRootPart", Part1 = "LowerTorso", C0 = c(0, 0, 0), C1 = c(0, -0.2, 0) },
			Waist = { Part0 = "LowerTorso", Part1 = "UpperTorso", C0 = c(0, 0.2, 0), C1 = c(0, -0.8, 0) },
			Neck = { Part0 = "UpperTorso", Part1 = "Head", C0 = c(0, 0.8, 0), C1 = c(0, -0.6, 0) },
			RightShoulder = { Part0 = "UpperTorso", Part1 = "RightUpperArm", C0 = c(1, 0.563, 0), C1 = c(-0.5, 0.392, 0) },
			LeftShoulder = { Part0 = "UpperTorso", Part1 = "LeftUpperArm", C0 = c(-1, 0.563, 0), C1 = c(0.5, 0.392, 0) },
			RightElbow = { Part0 = "RightUpperArm", Part1 = "RightLowerArm", C0 = c(0, -0.334, 0), C1 = c(0, 0.259, 0) },
			LeftElbow = { Part0 = "LeftUpperArm", Part1 = "LeftLowerArm", C0 = c(0, -0.334, 0), C1 = c(0, 0.259, 0) },
			RightWrist = { Part0 = "RightLowerArm", Part1 = "RightHand", C0 = c(0, -0.501, 0), C1 = c(0, 0.125, 0) },
			LeftWrist = { Part0 = "LeftLowerArm", Part1 = "LeftHand", C0 = c(0, -0.501, 0), C1 = c(0, 0.125, 0) },
			RightHip = { Part0 = "LowerTorso", Part1 = "RightUpperLeg", C0 = c(0.5, -0.2, 0), C1 = c(0, 0.42, 0) },
			LeftHip = { Part0 = "LowerTorso", Part1 = "LeftUpperLeg", C0 = c(-0.5, -0.2, 0), C1 = c(0, 0.42, 0) },
			RightKnee = { Part0 = "RightUpperLeg", Part1 = "RightLowerLeg", C0 = c(0, -0.4, 0), C1 = c(0, 0.35, 0) },
			LeftKnee = { Part0 = "LeftUpperLeg", Part1 = "LeftLowerLeg", C0 = c(0, -0.4, 0), C1 = c(0, 0.35, 0) },
			RightAnkle = { Part0 = "RightLowerLeg", Part1 = "RightFoot", C0 = c(0, -0.55, 0), C1 = c(0, 0.1, 0) },
			LeftAnkle = { Part0 = "LeftLowerLeg", Part1 = "LeftFoot", C0 = c(0, -0.55, 0), C1 = c(0, 0.1, 0) },
		},
	}
end

local function place(shape, transforms)
	local frames = { HumanoidRootPart = CFrame.new() }
	for _ = 1, 10 do
		for name, j in shape.Joints do
			if frames[j.Part0] and not frames[j.Part1] then
				frames[j.Part1] = frames[j.Part0] * j.C0 * (transforms[name] or CFrame.new()) * j.C1:Inverse()
			end
		end
	end
	return frames
end

local function corners(shape, frames, part, pick)
	local f, h = frames[part], shape.Sizes[part] / 2
	local best = nil
	for _, x in { -h.X, h.X } do
		for _, y in { -h.Y, h.Y } do
			for _, z in { -h.Z, h.Z } do
				local value = (f * Vector3.new(x, y, z)).Y
				best = if best == nil then value else pick(best, value)
			end
		end
	end
	return best
end
local function bottom(shape, frames, part)
	return corners(shape, frames, part, math.min)
end

local function finite(cf): boolean
	local components = { cf:GetComponents() }
	for _, value in components do
		if value ~= value or value == math.huge or value == -math.huge then
			return false
		end
	end
	return true
end

local function samePose(a, b): boolean
	for _, name in GymPoses.Joints do
		local x, y = a[name], b[name]
		if not x or not y then
			return false
		end
		if (x.Position - y.Position).Magnitude > 1e-4 or x.LookVector:Dot(y.LookVector) < 0.99999 or x.UpVector:Dot(y.UpVector) < 0.99999 then
			return false
		end
	end
	return true
end

local ctx1 = { Lift = 1.97, Scale = 1, Geo = {} }
local allFinite, allComplete, allLoop, allRest, loadEnds, smooth = true, true, true, true, true, true
for kind, def in GymPoses.Kinds do
	local machine = Gym.Machines[kind]
	local ctx = { Lift = 1.97, Scale = 1, Geo = if machine then machine.Geo else {} }
	local previous = nil
	for i = 0, 100 do
		local t = i / 100
		local pose = def.Pose(t, ctx)
		for _, name in GymPoses.Joints do
			if not pose[name] then
				allComplete = false
			elseif not finite(pose[name]) then
				allFinite = false
			end
		end
		local load = def.Load(t)
		if load ~= load or math.abs(load) > 1.0001 then
			allFinite = false
		end
		-- Sin tirones: entre dos muestras seguidas (1 % del ciclo) ninguna articulación gira mucho
		if previous then
			for _, name in GymPoses.Joints do
				local a, b = previous[name], pose[name]
				if a and b and (a.LookVector:Dot(b.LookVector) < 0.9 or (a.Position - b.Position).Magnitude > 0.25) then
					smooth = false
					print("      tirón:", kind, name, t)
				end
			end
		end
		previous = pose
	end
	if not samePose(def.Pose(0, ctx), def.Pose(1, ctx)) then
		allLoop = false
		print("      no empieza y acaba igual:", kind)
	end
	if not near(def.Load(0), def.Load(1) % 1, 1e-6) and not (def.Loop and near(def.Load(0), 0) and near(def.Load(1), 1)) then
		loadEnds = false
		print("      carga:", kind)
	end
	if not def.Loop then
		-- Las repeticiones empiezan y acaban en reposo (carga 0)
		if not near(def.Load(0), 0, 1e-6) or not near(def.Load(1), 0, 1e-6) then
			allRest = false
			print("      reposo:", kind)
		end
	end
	check(def.Period > 0.2 and def.Period < 10, ("%s: ciclo de %.1f s"):format(kind, def.Period))
end
check(allComplete, "cada postura dice dónde va cada articulación")
check(allFinite, "todas dan números normales (sin NaN) en todo el ciclo")
check(smooth, "sin tirones a lo largo del ciclo")
check(allLoop, "cada ejercicio acaba en la misma postura en la que empieza (se puede repetir)")
check(allRest, "las repeticiones de pesas empiezan y acaban en reposo")
check(loadEnds, "la máquina también vuelve a su sitio al acabar cada ciclo")
local _ = ctx1

print("▶ Entrar y salir suave")
check(GymPoses.ease(0) == 0 and GymPoses.ease(1) == 1 and GymPoses.ease(0.5) == 0.5, "la curva empieza en 0 y acaba en 1")
check(GymPoses.ease(-3) == 0 and GymPoses.ease(9) == 1, "y no se sale")
local base = CFrame.new(0.1, 0.2, 0) * CFrame.Angles(0.3, 0, 0)
local target = CFrame.Angles(1.2, 0.1, 0)
check(GymPoses.blend(base, target, 0) == base, "con peso 0 se queda la animación de siempre")
check(GymPoses.blend(base, target, 1) == target, "con peso 1, el ejercicio")
local mid = GymPoses.blend(base, target, 0.5)
check(finite(mid) and mid.LookVector:Dot(base.LookVector) < 1 and mid.LookVector:Dot(target.LookVector) < 1, "a medias, entre las dos")
local w = 0
local steps = 0
while w < 1 and steps < 100 do
	w = GymPoses.weight(w, 1, 1 / 60, 0.45)
	steps += 1
end
check(steps >= 20 and steps <= 30, ("entra en unos %d frames (≈0,45 s), sin saltos"):format(steps))
w = GymPoses.weight(1, 0, 10, 0.45)
check(w == 0, "y sale hasta 0 (sin pasarse)")

---------------------------------------------------------------------
print("▶ Con un cuerpo de verdad (R15)")
for _, scale in { 1, 0.65 } do
	local shape = rig(scale)
	local standing = place(shape, {})
	local feet = math.min(bottom(shape, standing, "RightFoot"), bottom(shape, standing, "LeftFoot"))
	local lift = -feet -- la raíz está a esta altura sobre el suelo
	local label = if scale == 1 then "adulto" else "niño"
	local function ctxFor(kind)
		return { Lift = lift, Scale = scale, Geo = Gym.Machines[kind].Geo }
	end
	local function height(frames, part)
		return bottom(shape, frames, part) + lift -- sobre el suelo
	end
	-- Sentado: los muslos apoyan en el asiento
	for _, kind in { "PressHombros", "Jalon", "Mancuernas", "Bici" } do
		local seat = Gym.Machines[kind].Geo.Seat
		local frames = place(shape, GymPoses.Kinds[kind].Pose(0, ctxFor(kind)))
		local thigh = math.min(height(frames, "RightUpperLeg"), height(frames, "LeftUpperLeg"))
		check(math.abs(thigh - seat) < 0.3 * scale + 0.15, ("%s (%s): sentado sobre el asiento (%.2f / %.2f)"):format(kind, label, thigh, seat))
	end
	-- Tumbado: la espalda apoya en el banco o en la esterilla
	for _, spec in { { "PressBanca", "Bench" }, { "Abdominales", "Mat" } } do
		local top = Gym.Machines[spec[1]].Geo[spec[2]]
		local frames = place(shape, GymPoses.Kinds[spec[1]].Pose(0, ctxFor(spec[1])))
		local back = math.min(height(frames, "UpperTorso"), height(frames, "LowerTorso"))
		check(math.abs(back - top) < 0.2, ("%s (%s): la espalda apoyada (%.2f / %.2f)"):format(spec[1], label, back, top))
		check(frames.UpperTorso.UpVector.Y < 0.3, ("%s (%s): tumbado de verdad"):format(spec[1], label))
	end
	-- Sentadilla: baja la cadera y los pies no se mueven del suelo
	local squatOk, squatDown = true, false
	local restFrames = place(shape, GymPoses.Kinds.Sentadilla.Pose(0, ctxFor("Sentadilla")))
	for i = 0, 20 do
		local frames = place(shape, GymPoses.Kinds.Sentadilla.Pose(i / 20, ctxFor("Sentadilla")))
		local f = math.min(height(frames, "RightFoot"), height(frames, "LeftFoot"))
		local slide = (frames.RightFoot.Position - restFrames.RightFoot.Position).Magnitude
		if math.abs(f) > 0.12 * scale + 0.02 or slide > 0.15 * scale then
			squatOk = false
		end
		if frames.LowerTorso.Position.Y < restFrames.LowerTorso.Position.Y - 0.6 * scale then
			squatDown = true
		end
	end
	check(squatOk, ("Sentadilla (%s): los pies quietos en el suelo"):format(label))
	check(squatDown, ("Sentadilla (%s): la cadera baja de verdad"):format(label))
	-- Dominadas: colgado con las manos en la barra
	local bar = Gym.Machines.Dominadas.Geo.Bar
	local hang = place(shape, GymPoses.Kinds.Dominadas.Pose(0, ctxFor("Dominadas")))
	local hands = (hang.RightHand.Position.Y + hang.LeftHand.Position.Y) / 2 + lift
	check(math.abs(hands - bar) < 0.6, ("Dominadas (%s): las manos en la barra (%.2f / %.2f)"):format(label, hands, bar))
	local up = place(shape, GymPoses.Kinds.Dominadas.Pose(0.4, ctxFor("Dominadas")))
	check(up.Head.Position.Y > hang.Head.Position.Y + 0.8 * scale, ("Dominadas (%s): sube el cuerpo"):format(label))
	-- Cinta: pisa la cinta, no el suelo de debajo (ni flota)
	local run = place(shape, GymPoses.Kinds.Cinta.Pose(0.25, ctxFor("Cinta")))
	local runFeet = math.min(height(run, "RightFoot"), height(run, "LeftFoot"))
	check(runFeet > Gym.Machines.Cinta.Geo.Belt - 0.25 and runFeet < Gym.Machines.Cinta.Geo.Belt + 0.5, ("Cinta (%s): corre sobre la cinta (%.2f)"):format(label, runFeet))
	-- Press de banca: la barra (las manos) sube con los brazos estirados y baja al pecho
	local press = place(shape, GymPoses.Kinds.PressBanca.Pose(0, ctxFor("PressBanca")))
	local chest = place(shape, GymPoses.Kinds.PressBanca.Pose(0.5, ctxFor("PressBanca")))
	check(press.RightHand.Position.Y > chest.RightHand.Position.Y + 0.6 * scale, ("Press de banca (%s): la barra sube y baja"):format(label))
end

print()
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
