-- Prueba del movimiento fluido (Controllers/Locomotion, PoseLayers, FootCamera y los gestos de
-- ReactMotion) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-motion.luau
--
-- Comprueba que:
--   * las curvas (ease, easeOut) empiezan en 0, acaban en 1 y no se salen
--   * los pesos que entran y salen (fade, smooth) siempre quedan entre 0 y 1, y no dependen de los FPS
--   * arrancar y frenar son suaves pero rápidos (ni instantáneos ni lentos) y nunca se pasan
--   * inclinarse, mirar a la cámara, aterrizar y deslizarse al asiento dan valores normales, empiezan
--     y acaban en la postura normal y van hacia el lado correcto
--   * el campo de visión al correr y la distancia de la cámara dentro y fuera tienen sentido
--   * PoseLayers: varias capas en la misma articulación no se acumulan frame a frame y, cuando
--     dejan de escribir, la articulación vuelve a su animación
--   * el gesto al usar un cartel es el que toca (comer, beber, coger del suelo, alcanzar o ninguno)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Enum = roblox.CFrame, roblox.Vector3, roblox.Enum

-- shared/Joints (articulaciones Motor6D o AnimationConstraint): lo piden los módulos al cargarse
local Joints = luau.load(fs.readFile("src/shared/Joints.luau"), { debugName = "Joints", environment = setmetatable({ CFrame = roblox.CFrame }, { __index = getfenv(1) }) })()
local fakeGame = { GetService = function(_, name)
	return { Name = name, Shared = { Joints = Joints } }
end }
local function load(path: string, extra: { [string]: any }?): any
	local env = { CFrame = CFrame, Vector3 = Vector3, Color3 = roblox.Color3, Enum = Enum, game = fakeGame, workspace = {}, script = {}, RaycastParams = { new = function()
		return {}
	end }, require = function(what)
		if what == Joints then
			return Joints
		end
		return require(what)
	end }
	for key, value in extra or {} do
		env[key] = value
	end
	return luau.load(fs.readFile(path), { debugName = path, environment = setmetatable(env, { __index = getfenv(1) }) })()
end

local Locomotion = load("src/client/Controllers/Locomotion.luau")
local FootCamera = load("src/client/Controllers/FootCamera.luau")
local PoseLayers = load("src/client/Controllers/PoseLayers.luau", { game = nil })
local ReactMotion = load("src/client/Controllers/ReactMotion.luau")

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function finite(x: number): boolean
	return x == x and math.abs(x) < math.huge
end

-- El mayor ángulo o desplazamiento de una postura (0 = postura normal)
local function amount(pose: { [string]: any }): number
	local most = 0
	for _, cf in pose do
		local x, y, z = cf:ToEulerAnglesXYZ()
		most = math.max(most, math.abs(x), math.abs(y), math.abs(z), cf.Position.Magnitude)
	end
	return most
end

local function poseFinite(pose: { [string]: any }): boolean
	for _, cf in pose do
		local x, y, z = cf:ToEulerAnglesXYZ()
		for _, v in { x, y, z, cf.Position.X, cf.Position.Y, cf.Position.Z } do
			if not finite(v) then
				return false
			end
		end
	end
	return true
end

local function roll(cf): number
	local _, _, z = cf:ToEulerAnglesXYZ()
	return z
end
local function pitch(cf): number
	return (cf:ToEulerAnglesXYZ())
end

---------------------------------------------------------------------
print("\n▶ Curvas y pesos")
for name, curve in { ease = Locomotion.ease, easeOut = Locomotion.easeOut } do
	local ok, monotonic, last = true, true, -1
	for i = -5, 45 do
		local v = curve(i / 40)
		ok = ok and finite(v) and v >= 0 and v <= 1
		monotonic = monotonic and v >= last - 1e-9
		last = v
	end
	check(curve(0) == 0 and math.abs(curve(1) - 1) < 1e-9, name .. ": empieza en 0 y acaba en 1")
	check(ok, name .. ": siempre entre 0 y 1 (también fuera de 0..1)")
	check(monotonic, name .. ": nunca da marcha atrás")
end
check(Locomotion.easeOut(0.25) > 0.25, "easeOut arranca rápido y se posa suave")

local w, inRange = 0, true
for i = 1, 200 do
	w = Locomotion.fade(w, i < 100, 1 / 60, 0.25)
	inRange = inRange and w >= 0 and w <= 1
end
check(inRange, "fade: el peso nunca sale de 0..1")
local up = 0
for _ = 1, 15 do
	up = Locomotion.fade(up, true, 1 / 60, 0.25)
end
check(up > 0.95 and up <= 1, ("fade: entra del todo en 0,25 s (%.2f)"):format(up))
check(Locomotion.fade(0.5, true, 1, 0) == 1 and Locomotion.fade(0.5, false, 1, 0) == 0, "fade: con 0 segundos es inmediato y sin pasarse")

local a60, a30 = 0, 0
for _ = 1, 60 do
	a60 = Locomotion.smooth(a60, 1, 5, 1 / 60)
end
for _ = 1, 30 do
	a30 = Locomotion.smooth(a30, 1, 5, 1 / 30)
end
check(math.abs(a60 - a30) < 1e-6, "smooth: igual a 30 y a 60 FPS")
check(a60 > 0 and a60 < 1, "smooth: se acerca sin pasarse")
check(Locomotion.smooth(0.3, 0.3, 5, 1 / 60) == 0.3, "smooth: si ya está, no se mueve")
check(math.abs(Locomotion.smooth(0, 1, 5, -1)) < 1e-9, "smooth: con un dt negativo no hace nada raro")

---------------------------------------------------------------------
print("\n▶ Arrancar y frenar")
local ACCEL, DECEL = 11, 15
local function run(from: Vector3, to: Vector3, seconds: number, dt: number): Vector3
	local v = from
	for _ = 1, math.floor(seconds / dt + 0.5) do
		v = Locomotion.approach(v, to, dt, ACCEL, DECEL)
	end
	return v
end
local target = Vector3.new(16, 0, 0)
check(run(Vector3.zero, target, 1 / 60, 1 / 60).Magnitude < 8, "No arranca de golpe (primer frame)")
check(run(Vector3.zero, target, 0.25, 1 / 60).Magnitude > 16 * 0.9, "A los 0,25 s ya va a más del 90 %")
check(run(Vector3.zero, target, 1, 1 / 60) == target, "Acaba exactamente en la velocidad pedida")
local stop = run(target, Vector3.zero, 0.2, 1 / 60)
check(stop.Magnitude < 16 * 0.1, ("Frena en unos 0,2 s (%.2f)"):format(stop.Magnitude))
check(run(target, Vector3.zero, 1, 1 / 60) == Vector3.zero, "Y se para del todo")
local over, fine, v = false, true, Vector3.zero
for _ = 1, 120 do
	v = Locomotion.approach(v, target, 1 / 60, ACCEL, DECEL)
	over = over or v.Magnitude > 16 + 1e-6
	fine = fine and finite(v.X) and finite(v.Z)
end
check(not over and fine, "Nunca se pasa de la velocidad pedida y siempre da números normales")
local turn = run(target, Vector3.new(0, 0, 16), 0.1, 1 / 60)
check(turn.Magnitude < 16 and turn.X > 0 and turn.Z > 0, "Un giro cerrado frena un poco y gira poco a poco")
check(math.abs(run(Vector3.zero, target, 0.3, 1 / 30).Magnitude - run(Vector3.zero, target, 0.3, 1 / 120).Magnitude) < 0.05, "Igual a 30 que a 120 FPS")
check(math.abs(Locomotion.angleDelta(3, -3) - (2 * math.pi - 6)) < 1e-9, "angleDelta da la vuelta corta")

---------------------------------------------------------------------
print("\n▶ Inclinarse y mirar")
local still = Locomotion.leanPose(0, 0, 0, 0)
check(amount(still) < 1e-6, "Quieto no se inclina")
local left = Locomotion.leanPose(4, 1, 0, 0)
local right = Locomotion.leanPose(-4, 1, 0, 0)
check(roll(left.Root) > 0 and roll(right.Root) < 0, "Se inclina hacia dentro del giro (a un lado u otro)")
check(roll(left.Waist) * roll(left.Root) < 0, "El pecho compensa (la cabeza va recta)")
check(pitch(Locomotion.leanPose(0, 1.5, 0, 1).Root) < -0.05, "Corriendo va echado hacia delante")
check(pitch(Locomotion.leanPose(0, 1, 30, 0).Root) < pitch(Locomotion.leanPose(0, 1, -30, 0).Root), "Al acelerar se echa adelante y al frenar atrás")
local worst = 0
for _, args in { { 1e3, 50, 1e3, 5 }, { -1e3, -5, -1e3, -5 }, { 0 / 1, 2, 60, 1 } } do
	local pose = Locomotion.leanPose(args[1], args[2], args[3], args[4])
	check(poseFinite(pose), "leanPose da valores normales con entradas extremas")
	worst = math.max(worst, amount(pose))
end
check(worst <= 0.25, ("Nunca se inclina de más (%.2f rad)"):format(worst))
check(amount(Locomotion.lookPose(1, 0.5, 0)) < 1e-6, "Mirar con peso 0 no mueve la cabeza")
local look = Locomotion.lookPose(9, 9, 1)
check(poseFinite(look) and amount(look) < 0.7, "Mirar a la cámara nunca tuerce el cuello de más")
local _, lookYaw = look.Neck:ToEulerAnglesXYZ()
check(lookYaw > 0, "Si la cámara mira a su izquierda, la cabeza gira a su izquierda")
local yaw, p, facing = Locomotion.cameraLook(CFrame.new(), Vector3.new(0, 0, -1))
check(math.abs(yaw) < 1e-6 and math.abs(p) < 1e-6 and facing == 1, "Cámara detrás mirando al frente: cabeza recta")
local _, _, front = Locomotion.cameraLook(CFrame.new(), Vector3.new(0, 0, 1))
check(front == 0, "Cámara de frente (mirándole a la cara): no gira la cabeza hacia atrás")
local _, _, none = Locomotion.cameraLook(CFrame.new(), Vector3.new(0, -1, 0))
check(none == 0, "Cámara mirando justo abajo: no hace nada raro")

---------------------------------------------------------------------
print("\n▶ Aterrizar")
check(Locomotion.landing(10) == nil, "Un escalón no hace nada")
local kind, strength = Locomotion.landing(50)
check(kind == "Land" and strength > 0 and strength < 1, "Un salto normal: se agacha un poco")
local k2, s2 = Locomotion.landing(80)
check(k2 == "Land" and s2 > strength, "Más alto, más se agacha")
check(Locomotion.landing(140) == "Stumble", "Desde muy alto: traspiés")
for _, name in { "Land", "Stumble" } do
	local def = ReactMotion.Kinds[name]
	check(amount(def.Pose(0, { Strength = 1 })) < 0.02 and amount(def.Pose(1, { Strength = 1 })) < 0.02, name .. ": empieza y acaba de pie")
end
check(amount(ReactMotion.Kinds.Land.Pose(0.2, { Strength = 0 })) < 1e-6, "Land con fuerza 0 no hace nada")
check(amount(ReactMotion.Kinds.Land.Pose(0.2, { Strength = 1 })) > amount(ReactMotion.Kinds.Land.Pose(0.2, { Strength = 0.3 })), "Land: cuanta más fuerza, más se agacha")

---------------------------------------------------------------------
print("\n▶ Deslizarse al asiento")
local c0 = CFrame.new(0, -1, 0) * CFrame.Angles(0, 0.3, 0)
local c1 = CFrame.new(0, 0.2, 0)
local from = CFrame.new(10, 3, 5) * CFrame.Angles(0, 1.2, 0)
local seat = CFrame.new(11.5, 2.2, 6) * CFrame.Angles(0, -0.4, 0)
local function torso(root, transform)
	return root * c0 * transform * c1:Inverse()
end
local startGlide = Locomotion.glideOffset(seat, from, c0, 0)
local seen = torso(seat, startGlide)
local expected = torso(from, CFrame.identity)
check((seen.Position - expected.Position).Magnitude < 1e-4 and seen.LookVector:Dot(expected.LookVector) > 0.9999, "Al empezar, el cuerpo se ve donde estaba")
check(amount({ Locomotion.glideOffset(seat, from, c0, 1) }) < 1e-4, "Al acabar, está en el asiento (sin retoque)")
local mid = torso(seat, Locomotion.glideOffset(seat, from, c0, 0.5))
local d1 = (mid.Position - expected.Position).Magnitude
local d2 = (mid.Position - torso(seat, CFrame.identity).Position).Magnitude
check(d1 > 0.05 and d2 > 0.05, "A mitad, está entre los dos sitios")
check(amount({ Locomotion.glideOffset(seat, seat, c0, 0.3) }) < 1e-4, "Si no se ha movido, no hay nada que deslizar")

---------------------------------------------------------------------
print("\n▶ Cámara")
check(Locomotion.fov(70, 0) == 70 and Locomotion.fov(70, 1) == 77, "Corriendo el campo de visión se abre 7°")
check(Locomotion.fov(70, 5) == 77 and Locomotion.fov(70, -2) == 70, "Y nunca más de eso")
check(FootCamera.maxZoom(true, false) < FootCamera.maxZoom(false, false), "Dentro de un edificio la cámara no se aleja tanto")
check(FootCamera.maxZoom(true, false) >= 8, "Pero se sigue viendo al personaje")
check(FootCamera.maxZoom(true, true) > FootCamera.maxZoom(false, false), "En modo foto se aleja más (también dentro)")

---------------------------------------------------------------------
print("\n▶ PoseLayers: varias capas en la misma articulación")
local joint = { Transform = CFrame.Angles(0.2, 0, 0) } -- lo que dejó la animación
local tilt = CFrame.Angles(0, 0, 0.1)
local nod = CFrame.Angles(0.05, 0, 0)
local layerA, layerB = true, true
PoseLayers.reset()
PoseLayers.add("A", 10, function()
	if layerA then
		PoseLayers.write(joint, tilt * PoseLayers.read(joint))
	end
end)
PoseLayers.add("B", 30, function()
	if layerB then
		PoseLayers.write(joint, nod * PoseLayers.read(joint))
	end
end)
local want = nod * tilt * CFrame.Angles(0.2, 0, 0)
for _ = 1, 120 do
	PoseLayers.step(1 / 60, 0) -- la animación no toca la articulación
end
check(PoseLayers.same(joint.Transform, want), "Sin animación encima, 120 frames después sigue igual (no se acumula)")
for i = 1, 30 do
	local anim = CFrame.Angles(0.01 * i, 0, 0)
	joint.Transform = anim -- la animación escribe cada frame
	PoseLayers.step(1 / 60, 0)
	if i == 30 then
		check(PoseLayers.same(joint.Transform, nod * tilt * anim), "Con la animación moviéndose, las capas van encima de ella")
	end
end
layerB = false
PoseLayers.step(1 / 60, 0)
check(PoseLayers.same(joint.Transform, tilt * CFrame.Angles(0.3, 0, 0)), "Si una capa deja de escribir, se quita solo lo suyo")
layerA = false
PoseLayers.step(1 / 60, 0)
check(PoseLayers.same(joint.Transform, CFrame.Angles(0.3, 0, 0)), "Si ninguna escribe, vuelve a la animación")
PoseLayers.step(1 / 60, 0)
check(PoseLayers.same(joint.Transform, CFrame.Angles(0.3, 0, 0)), "Y se queda así")
local order = {}
PoseLayers.reset()
PoseLayers.add("Tres", 30, function()
	table.insert(order, 3)
end)
PoseLayers.add("Uno", 10, function()
	table.insert(order, 1)
end)
PoseLayers.add("Dos", 20, function()
	table.insert(order, 2)
end)
PoseLayers.add("Rota", 25, function()
	error("capa rota")
end)
PoseLayers.step(1 / 60, 0)
check(table.concat(order, ",") == "1,2,3", "Las capas van en orden (AgeMotion, Locomotion, ReactMotion) y una rota no para a las demás")
PoseLayers.reset()

---------------------------------------------------------------------
print("\n▶ Gestos de las acciones")
local cases = {
	{ "Sentarse", 0, nil },
	{ "Montar", 0, nil },
	{ "Hablar", 0.5, nil },
	{ "Comer", 0, "Eat" },
	{ "Desayunar", 0, "Eat" },
	{ "Beber agua", 0, "Drink" },
	{ "Tomar un café", 0, "Drink" },
	{ "Recoger", -0.9, "PickUp" },
	{ "Coger", 0.2, "Reach" },
	{ "Abrir", 0.6, "Reach" },
	{ "Comprar aguacate", 0, "Reach" },
	{ "Coger comida", 0.1, "Eat" },
	{ "Coger fruta", 0.1, "Eat" },
	{ "Mirar", -0.95, "PickUp" },
	{ nil, 0, "Reach" },
}
for _, case in cases do
	local got = ReactMotion.gestureFor(case[1], case[2])
	check(got == case[3], ("«%s» → %s"):format(tostring(case[1]), tostring(case[3])))
end
check(ReactMotion.foodGesture("Café con leche") == "Drink" and ReactMotion.foodGesture("Zumo de naranja") == "Drink", "Las bebidas de la mochila se beben")
check(ReactMotion.foodGesture("Aguacate") == "Eat" and ReactMotion.foodGesture("Bocadillo") == "Eat" and ReactMotion.foodGesture(nil) == "Eat", "Lo demás se come")
for _, name in { "Reach", "PickUp", "Eat", "Drink", "Throw", "Cast", "Reel" } do
	local def = ReactMotion.Kinds[name]
	local fineAll = true
	for i = 0, 30 do
		fineAll = fineAll and poseFinite(def.Pose(i / 30, { Height = (i % 3) - 1 }))
	end
	check(fineAll, name .. ": valores normales en toda la animación")
	check(def.Duration >= 0.3, name .. ": no es un tirón (dura al menos 0,3 s)")
end
local low = ReactMotion.Kinds.Reach.Pose(0.45, { Height = -1 })
local high = ReactMotion.Kinds.Reach.Pose(0.45, { Height = 1 })
check(pitch(high.RightShoulder) > pitch(low.RightShoulder), "Alcanzar algo alto sube más el brazo que algo bajo")
check(ReactMotion.Kinds.PickUp.Pose(0.45, {}).Root.Position.Y < -0.5, "Para coger del suelo se agacha")
check(amount(ReactMotion.Holds.Flashlight(0, 0)) < 1e-6 and amount(ReactMotion.Holds.Rod(0, 2)) < 1e-6, "Linterna y caña con peso 0 no hacen nada")

---------------------------------------------------------------------
print("\n▶ Voltereta de esquivar (Controllers/RollMotion)")
do
	local Combat = luau.load(fs.readFile("src/shared/Combat.luau"), { debugName = "Combat" })()
	local rollGame = { GetService = function(_, name)
		return { Name = name, Shared = { Joints = Joints, Combat = Combat }, GetPlayerFromCharacter = function()
			return nil
		end }
	end }
	local RollMotion = load("src/client/Controllers/RollMotion.luau", { game = rollGame, require = function(what)
		if what == Joints then
			return Joints
		elseif what == Combat then
			return Combat
		end
		return require(what)
	end })
	local function near(a: CFrame, b: CFrame): boolean
		return (a.Position - b.Position).Magnitude < 1e-3 and a.LookVector:Dot(b.LookVector) > 0.9999 and a.UpVector:Dot(b.UpVector) > 0.9999
	end
	check(Combat.RollTime >= 0.6 and Combat.RollTime <= 0.8, ("Dura entre 0,6 y 0,8 s (%.2f)"):format(Combat.RollTime))
	for _, rig in { "R15", "R6" } do
		check(amount(RollMotion.pose(0, rig)) < 1e-4 and amount(RollMotion.pose(1, rig)) < 1e-4, rig .. ": empieza y acaba en la postura normal (no deja el cuerpo torcido)")
		local fine = true
		for i = 0, 40 do
			fine = fine and poseFinite(RollMotion.pose(i / 40, rig))
		end
		check(fine, rig .. ": valores normales en toda la voltereta")
		local mid = RollMotion.pose(0.5, rig)
		-- (gira alrededor del centro de la bola, un poco por encima de la raíz en el R15: ese centro baja)
		local c = RollMotion.Pivot[rig]
		local center = mid.Root:PointToWorldSpace(Vector3.new(0, c, 0)).Y - c
		check(center < -0.5 and mid.RightHip and pitch(mid.RightHip) > 1.2, rig .. ": a mitad, el cuerpo baja y las piernas se recogen (hecho bola)")
		check(RollMotion.pose(0.3, rig).Root.UpVector.Z < -0.5, rig .. ": rueda hacia DELANTE (la cabeza va hacia delante y abajo)")
	end
	check(RollMotion.pose(0.5, "R6").RightKnee == nil and RollMotion.pose(0.5, "R15").RightKnee ~= nil, "El R6 no tiene rodillas ni codos: no se piden")
	check(math.abs(RollMotion.spin(1) + 2 * math.pi) < 1e-6 and math.abs(RollMotion.spin(0)) < 1e-6, "Una vuelta entera (2π) sobre el eje X")
	local monotonic = true
	for i = 1, 40 do
		monotonic = monotonic and RollMotion.spin(i / 40) <= RollMotion.spin((i - 1) / 40) + 1e-9
	end
	check(monotonic, "Gira siempre hacia el mismo lado (sin ir y volver)")
	check(RollMotion.weight(0) == 0 and RollMotion.weight(1) == 0 and RollMotion.weight(0.5) == 1, "Entra y sale suave (peso 0 → 1 → 0)")
	check(Combat.rollSpeed(0) == Combat.RollSpeed and Combat.rollSpeed(1) < Combat.RollSpeed * 0.5 and Combat.rollSpeed(1) > 0, "Sale con impulso y frena rodando (sin pararse en seco)")
	check(Combat.DodgeCooldown > Combat.RollTime and Combat.DodgeInvulnerable > 0 and Combat.DodgeInvulnerable < Combat.RollTime, "Con enfriamiento (más que la voltereta) y una invulnerabilidad corta")
	-- Las articulaciones del R6 tienen el C0 girado: el giro pedido en los ejes del torso tiene que salir igual
	local r6Root = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
	local r6Hip = CFrame.new(1, -1, 0) * CFrame.Angles(0, math.pi / 2, 0)
	local want = CFrame.Angles(-1.1, 0, 0) * CFrame.new(0, -0.4, 0)
	check(near(r6Root * RollMotion.toJoint(r6Root, want), r6Root.Rotation * CFrame.new(r6Root.Position) * want * r6Root.Rotation)
		or near(r6Root.Rotation * RollMotion.toJoint(r6Root, want), want * r6Root.Rotation), "R6: el giro pasa bien a los ejes del RootJoint (C0 girado)")
	local leg = (r6Hip.Rotation * RollMotion.toJoint(r6Hip, CFrame.Angles(1.2, 0, 0))):VectorToWorldSpace(Vector3.new(0, -1, 0))
	check(leg.Z < -0.5, "R6: la pierna se recoge hacia delante (no hacia un lado)")
	check(near(RollMotion.toJoint(CFrame.new(0, -1, 0), want), want), "R15 (C0 sin girar): el giro va tal cual")

	-- Con PoseLayers: mientras rueda se escriben las articulaciones; al acabar o al cortarse vuelven solas
	PoseLayers.reset()
	RollMotion._attach(PoseLayers)
	local anim = CFrame.Angles(0.15, 0, 0) -- lo que dejó la animación
	local function rig(): { [string]: any }
		local out = {}
		for name in RollMotion.Rigs.R15 do
			out[name] = { Transform = anim, C0 = CFrame.new(0, -1, 0), C1 = CFrame.identity }
		end
		return out
	end
	local state = Enum.HumanoidStateType.Running
	local model = { Parent = {} }
	local humanoid = { Parent = model, Health = 100, SeatPart = nil, Sit = false, PlatformStand = false, GetState = function()
		return state
	end }
	local joints = rig()
	PoseLayers.add("RollMotion", 35, function(_, now)
		RollMotion.step(now)
	end)
	RollMotion._add(model, humanoid, "R15", joints, 0, 0.7)
	PoseLayers.step(1 / 60, 0.35)
	check(not PoseLayers.same(joints.Root.Transform, anim) and RollMotion.isRolling(model :: any), "Rodando: la raíz gira (Transform de la articulación)")
	PoseLayers.step(1 / 60, 0.8)
	check(not RollMotion.isRolling(model :: any) and PoseLayers.same(joints.Root.Transform, anim) and PoseLayers.same(joints.RightKnee.Transform, anim), "Al acabar, todas las articulaciones vuelven a la animación")
	for _, cut in { "Health", "Sit", "SeatPart", "Swimming" } do
		joints = rig()
		RollMotion._add(model, humanoid, "R15", joints, 0, 0.7)
		PoseLayers.step(1 / 60, 0.3)
		local moved = not PoseLayers.same(joints.Root.Transform, anim)
		if cut == "Health" then
			humanoid.Health = 0
		elseif cut == "Sit" then
			humanoid.Sit = true
		elseif cut == "SeatPart" then
			humanoid.SeatPart = {}
		else
			state = Enum.HumanoidStateType.Swimming
		end
		PoseLayers.step(1 / 60, 0.35)
		check(moved and not RollMotion.isRolling(model :: any) and PoseLayers.same(joints.Root.Transform, anim), "Si " .. ({ Health = "muere", Sit = "se sienta", SeatPart = "sube a un asiento", Swimming = "cae al agua" })[cut] .. " a mitad, se corta y el cuerpo vuelve a su sitio")
		humanoid.Health, humanoid.Sit, humanoid.SeatPart, state = 100, false, nil, Enum.HumanoidStateType.Running
	end
	PoseLayers.reset()
	local controller = fs.readFile("src/client/Controllers/CombatController.luau")
	check(controller:find("RollMotion.roll(direction)", 1, true) ~= nil and (controller:find("Remote:FireServer(\"Dodge\")", 1, true) ~= nil or controller:find("send(\"Dodge\"", 1, true) ~= nil), "Esquivar = voltereta (RollMotion.roll) y el servidor da la invulnerabilidad (\"Dodge\")")
	local roll = fs.readFile("src/client/Controllers/RollMotion.luau")
	check(roll:find("VelocityConstraintMode.Plane", 1, true) ~= nil and roll:find("root.CFrame = CFrame.new(", 1, true) == nil, "El impulso es física en el plano (respeta paredes, no teletransporta)")
	local server = fs.readFile("src/server/Services/CombatService.luau")
	check(server:find("SetAttribute(\"Roll\"", 1, true) ~= nil and roll:find("GetAttributeChangedSignal(\"Roll\")", 1, true) ~= nil, "Los demás la ven: el servidor pone \"Roll\" y cada pantalla la dibuja")
end

print("")
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
