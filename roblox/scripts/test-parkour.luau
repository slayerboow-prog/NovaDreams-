-- Prueba de agacharse, tumbarse y el parkour (shared/Movement, Controllers/Stances y Controllers/Parkour)
-- FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-parkour.luau
--
-- Comprueba que:
--   * cada obstáculo (alto, grueso, caída detrás, velocidad, edad) da el salto que toca, o ninguno
--   * el camino del salto empieza donde estás, acaba de pie en el sitio de caer, no da saltos, pasa
--     por encima del obstáculo y respeta el sitio de caer
--   * tumbado, el cuerpo queda paralelo a la cuesta
--   * agachado, los pies se quedan en el suelo bajo la cadera (IK) y la cadera baja lo que toca
--   * las velocidades de cada postura y las reglas de cuándo se puede (bebé, montado, nadando…)
--   * las posturas dan valores normales y empiezan y acaban en cero

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Enum = roblox.CFrame, roblox.Vector3, roblox.Enum

local Movement = luau.load(fs.readFile("src/shared/Movement.luau"), {
	debugName = "Movement",
	environment = setmetatable({ Vector3 = Vector3 }, { __index = getfenv(1) }),
})()

local function load(path: string): any
	local env = {
		CFrame = CFrame, Vector3 = Vector3, Enum = Enum, script = {}, workspace = {},
		game = { GetService = function(_, name)
			return { Name = name, Shared = { Movement = "Movement" } }
		end },
		RaycastParams = { new = function()
			return {}
		end },
		require = function(what)
			assert(what == "Movement", "solo debería pedir Movement al cargarse: " .. tostring(what))
			return Movement
		end,
	}
	return luau.load(fs.readFile(path), { debugName = path, environment = setmetatable(env, { __index = getfenv(1) }) })()
end
local Stances = load("src/client/Controllers/Stances.luau")
local Parkour = load("src/client/Controllers/Parkour.luau")
local Locomotion = luau.load(fs.readFile("src/client/Controllers/Locomotion.luau"), {
	debugName = "Locomotion",
	environment = setmetatable({ CFrame = CFrame, Vector3 = Vector3, Enum = Enum, script = {}, workspace = {} }, { __index = getfenv(1) }),
})()

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

local function amount(pose): number
	local most = 0
	for _, cf in pose do
		local x, y, z = cf:ToEulerAnglesXYZ()
		most = math.max(most, math.abs(x), math.abs(y), math.abs(z), cf.Position.Magnitude)
	end
	return most
end

local function poseFinite(pose): boolean
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

---------------------------------------------------------------------
print("\n▶ Qué salto toca")
local cases = {
	{ "Valla (3 studs, fina)", { Height = 3, Depth = 0.5, Clear = true, Drop = 0, Speed = 12 }, "Speed" },
	{ "Barandilla baja corriendo", { Height = 2, Depth = 0.3, Clear = true, Drop = 0, Speed = 24 }, "Speed" },
	{ "Muro bajo y ancho corriendo", { Height = 3, Depth = 3.5, Clear = true, Drop = 0, Speed = 22 }, "Kong" },
	{ "Muro bajo y ancho andando", { Height = 3, Depth = 3.5, Clear = true, Drop = 0, Speed = 8 }, "Climb" },
	{ "Muro de 6 studs", { Height = 6, Depth = 1, Clear = true, Drop = 0, Speed = 12 }, "Climb" },
	{ "Borde de 8 studs con sitio arriba", { Height = 8, Depth = math.huge, Speed = 10 }, "Ledge" },
	{ "Bordillo (1 stud)", { Height = 1, Depth = 5, Clear = true, Speed = 12 }, nil },
	{ "Pared altísima", { Height = 12, Depth = 1, Clear = true, Speed = 12 }, nil },
	{ "Valla sin sitio detrás", { Height = 3, Depth = 0.5, Clear = false, Drop = 0, Speed = 12 }, nil },
	{ "Valla con un precipicio detrás", { Height = 3, Depth = 0.5, Clear = true, Drop = 40, Speed = 12 }, nil },
	{ "Muro ancho con precipicio: se sube y se queda", { Height = 3, Depth = 3, Clear = true, Drop = 40, Speed = 12 }, "Ledge" },
	{ "Bebé ante una valla", { Height = 2, Depth = 0.4, Clear = true, Drop = 0, Speed = 8, Stage = "Bebe" }, nil },
	{ "Niño: nada de kong", { Height = 3, Depth = 3.5, Clear = true, Drop = 0, Speed = 22, Stage = "Nino" }, "Climb" },
	{ "Niño (tamaño 0,6) con una valla de 2", { Height = 2, Depth = 0.3, Clear = true, Drop = 0, Speed = 10, Stage = "Nino", Scale = 0.6 }, "Speed" },
	{ "Mayor ante un muro de 6: no", { Height = 6, Depth = 1, Clear = true, Drop = 0, Speed = 8, Stage = "Mayor" }, nil },
	{ "Mayor ante una valla alta: trepa", { Height = 4, Depth = 0.5, Clear = true, Drop = 0, Speed = 8, Stage = "Mayor" }, "Climb" },
}
for _, case in cases do
	local got = Movement.classify(case[2])
	check(got == case[3], ("%s → %s%s"):format(case[1], tostring(case[3]), if got ~= case[3] then " (sale " .. tostring(got) .. ")" else ""))
end

---------------------------------------------------------------------
print("\n▶ Camino del salto")
local H = 3 -- cadera sobre los pies (adulto)
local function scenario(kind: string, height: number, depth: number, drop: number)
	local feet = 0
	local from = Vector3.new(0, feet + H, 0)
	local edge = Vector3.new(0, feet + height, -2)
	local far = edge + Vector3.new(0, 0, -depth)
	local landGround = feet - drop
	local land = if kind == "Ledge" then Vector3.new(0, feet + height + H, -3.2) else far + Vector3.new(0, 0, -2) + Vector3.new(0, landGround + H - (feet + height), 0)
	return Movement.path(kind, from, edge, far, land, H), from, edge, far, land
end
for _, def in { { "Speed", 3, 0.5, 0 }, { "Kong", 3, 3, 0 }, { "Climb", 6, 1, 0 }, { "Climb", 3, 3, 4 }, { "Ledge", 8, math.huge, 0 }, { "Speed", 3, 0.5, 6 } } do
	local kind, height, depth, drop = def[1], def[2], def[3], def[4]
	local points, from, edge, far, land = scenario(kind, height, if depth == math.huge then 0 else depth, drop)
	local name = ("%s (alto %d, caída %d)"):format(kind, height, drop)
	check((Movement.sample(points, 0) - from).Magnitude < 1e-6, name .. ": empieza donde estás")
	check((Movement.sample(points, 1) - land).Magnitude < 1e-6, name .. ": acaba de pie donde cae")
	local worst, prev, fine, overOk = 0, Movement.sample(points, 0), true, true
	local topY = edge.Y
	for i = 1, 400 do
		local u = Movement.timeCurve(i / 400)
		local p = Movement.sample(points, u)
		fine = fine and finite(p.X) and finite(p.Y) and finite(p.Z)
		worst = math.max(worst, (p - prev).Magnitude)
		prev = p
		-- Encima del obstáculo, la cadera va por encima de lo alto
		if kind ~= "Ledge" and p.Z < edge.Z - 0.2 and p.Z > far.Z + 0.2 then
			overOk = overOk and p.Y - H * 0.4 > topY
		end
	end
	check(fine, name .. ": valores normales")
	check(worst < 0.25, ("%s: sin saltos (paso más largo %.2f)"):format(name, worst))
	check(overOk, name .. ": pasa por encima (la cadera por encima de lo alto)")
	local highest = -math.huge
	for i = 0, 100 do
		highest = math.max(highest, Movement.sample(points, i / 100).Y)
	end
	check(highest > topY + H * 0.4, name .. ": el punto más alto está por encima del obstáculo")
end
local last = -1
local mono = true
for i = 0, 100 do
	local v = Movement.timeCurve(i / 100)
	mono = mono and v >= last - 1e-12 and v >= 0 and v <= 1
	last = v
end
check(mono and Movement.timeCurve(0) == 0 and Movement.timeCurve(1) == 1, "El tiempo del salto va de 0 a 1 sin volver atrás")
for _, kind in { "Speed", "Kong", "Climb", "Ledge" } do
	local d = Movement.duration(kind, 4, 1)
	check(d > 0.3 and d < 2, kind .. (": dura lo razonable (%.2f s)"):format(d))
end

---------------------------------------------------------------------
print("\n▶ Tumbado en una cuesta")
local function proneAxis(pitch: number, roll: number): Vector3
	local rotation = CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, 0, roll) * CFrame.Angles(-math.pi / 2, 0, 0)
	return rotation:VectorToWorldSpace(Vector3.new(0, 1, 0)) -- de los pies a la cabeza
end
local function sideAxis(pitch: number, roll: number): Vector3
	local rotation = CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, 0, roll) * CFrame.Angles(-math.pi / 2, 0, 0)
	return rotation:VectorToWorldSpace(Vector3.new(1, 0, 0))
end
local look = Vector3.new(0, 0, -1)
local p0, r0 = Movement.slopeAngles(Vector3.new(0, 1, 0), look)
check(math.abs(p0) < 1e-9 and math.abs(r0) < 1e-9, "En llano, recto")
local slope = math.rad(15)
local upAhead = Vector3.new(0, math.cos(slope), math.sin(slope)) -- cuesta arriba hacia delante (-Z)
local pitch, roll = Movement.slopeAngles(upAhead, look)
check(pitch > 0 and math.abs(roll) < 1e-6, "Cuesta arriba delante: la cabeza sube")
check(math.abs(proneAxis(pitch, roll):Dot(upAhead)) < 1e-6, "El cuerpo queda paralelo a la cuesta (hacia delante)")
local upRight = Vector3.new(-math.sin(slope), math.cos(slope), 0) -- sube hacia la derecha (+X)
local p2, r2 = Movement.slopeAngles(upRight, look)
check(r2 > 0 and math.abs(p2) < 1e-6, "Cuesta que sube a la derecha: el lado derecho sube")
check(math.abs(sideAxis(p2, r2):Dot(upRight)) < 1e-6, "Y de lado también queda paralelo")
local both = Vector3.new(-0.2, 1, 0.25).Unit
local p3, r3 = Movement.slopeAngles(both, look)
check(math.abs(proneAxis(p3, r3):Dot(both)) < 0.02, "En diagonal, casi paralelo")
check(Movement.slopeDegrees(Vector3.new(0, 1, 0)) < 1e-6 and math.abs(Movement.slopeDegrees(upAhead) - 15) < 1e-3, "Grados de la cuesta")

---------------------------------------------------------------------
print("\n▶ Agachado: pies en el suelo")
for _, legs in { { 1.2, 1.2 }, { 1.1, 1.35 }, { 0.7, 0.8 } } do
	local thigh, shin = legs[1], legs[2]
	for _, drop in { 0, 0.3, 0.7 } do
		local hip, knee, ankle = Movement.crouchLegs(drop, thigh, shin)
		-- muslo y espinilla (x>0 hacia delante = -Z)
		local a1 = hip
		local a2 = hip + knee
		local y = -(thigh * math.cos(a1) + shin * math.cos(a2))
		local z = -(thigh * math.sin(a1) + shin * math.sin(a2))
		local name = ("pierna %.1f+%.2f, bajar %.1f"):format(thigh, shin, drop)
		check(math.abs(-y - (thigh + shin - drop)) < 1e-4, name .. ": la cadera baja justo eso")
		check(math.abs(z) < 1e-4, name .. ": el pie sigue debajo")
		check(math.abs(a2 + ankle) < 1e-6, name .. ": el pie plano")
		check(knee <= 0 and finite(hip) and finite(ankle), name .. ": la rodilla dobla hacia atrás")
	end
end

---------------------------------------------------------------------
print("\n▶ Agachado: piernas (IK) y paso")
local okIK = true
for _, legs in { { 1.2, 1.2 }, { 1.0, 1.3 }, { 0.6, 0.7 } } do
	local a, b = legs[1], legs[2]
	for _, target in { Vector3.new(0, -(a + b) * 0.66, 0), Vector3.new(0.1, -(a + b) * 0.6, -0.5 * a), Vector3.new(-0.05, -(a + b) * 0.7, 0.4 * a), Vector3.new(0.2, -(a + b) * 0.5, 0.2) } do
		local hipT, kneeT = Stances.legIK(target, a, b)
		local knee = hipT * Vector3.new(0, -a, 0)
		local ankle = knee + (hipT * kneeT):VectorToWorldSpace(Vector3.new(0, -b, 0))
		local kx = select(1, kneeT:ToEulerAnglesXYZ())
		-- la rodilla por delante de la línea cadera-tobillo (dobla hacia atrás, como una pierna)
		local line = ankle.Unit
		local side = knee - line * knee:Dot(line)
		okIK = okIK and (ankle - target).Magnitude < 1e-3 and kx < 0 and side.Z < 1e-6
	end
end
check(okIK, "IK: el tobillo llega justo a su sitio y la rodilla dobla hacia atrás (apunta adelante)")
local far = Vector3.new(0, -10, 0)
local hipT, kneeT = Stances.legIK(far, 1, 1)
check(poseFinite({ hipT, kneeT }) and (hipT * Vector3.new(0, -1, 0)).Y < -0.99, "IK: si no llega, se estira hacia allí (sin NaN)")
local G = Stances.Gait
local okGait, prevAlong, jumpMax = true, nil, 0
for i = 0, 400 do
	local u = i / 400
	local along, up = Stances.gaitFoot(u, G.Duty)
	okGait = okGait and finite(along) and up >= 0 and up <= 1 and along > -0.75 and along < 0.75
	if u < G.Duty then
		okGait = okGait and up == 0 and math.abs(along - (0.5 - u / G.Duty)) < 1e-9
	end
	if prevAlong then
		jumpMax = math.max(jumpMax, math.abs(along - prevAlong))
	end
	prevAlong = along
end
local a0 = Stances.gaitFoot(0, G.Duty)
local a1 = Stances.gaitFoot(0.99999, G.Duty)
check(okGait, "Paso: apoyado va hacia atrás a ritmo fijo (pegado al suelo) y por el aire sube y vuelve")
check(jumpMax < 0.02 and math.abs(a0 - a1) < 1e-3, "Paso: sin saltos en todo el ciclo (ni al pisar ni al despegar)")
local okRate = true
for _, v in { 0.5, 2, 5, 7.2 } do
	local hz, stride = Stances.gaitRate(v, 2.3)
	-- el pie apoyado recorre la zancada en Duty/hz segundos: a la velocidad del cuerpo
	okRate = okRate and hz > 0 and math.abs(stride / (G.Duty / hz) - v) < 1e-6
end
local hzA = Stances.gaitRate(2, 2.3)
local hzB = Stances.gaitRate(7, 2.3)
local _, strideMax = Stances.gaitRate(100, 2.3)
check(okRate, "Paso: el pie apoyado va a la velocidad del cuerpo (no patina)")
check(hzB > hzA and strideMax <= G.MaxStride * 2.3 + 1e-9, "Paso: más deprisa, más pasos; la zancada nunca pasa de lo que da la pierna")
local _, strideKid = Stances.gaitRate(5, 1.2)
local _, strideAdult = Stances.gaitRate(5, 2.3)
check(strideKid < strideAdult, "Paso: un niño (pierna corta) da pasos más cortos a la misma velocidad")
local still = Stances.crouchPose(1, 0, 0, 0, 0, 0, 1)
local walking = Stances.crouchPose(1, 0, 0, 0, 1, 0, 0)
check(select(1, still.Pelvis:ToEulerAnglesXYZ()) < -0.2 and select(1, still.Waist:ToEulerAnglesXYZ()) < 0, "Agachado: la cadera y el pecho se inclinan adelante")
check(select(1, walking.RightShoulder:ToEulerAnglesXYZ()) < select(1, walking.LeftShoulder:ToEulerAnglesXYZ()), "Andando agachado: con el pie derecho delante, el brazo derecho va atrás")
local total = select(1, still.Pelvis:ToEulerAnglesXYZ()) + select(1, still.Waist:ToEulerAnglesXYZ()) + select(1, still.Neck:ToEulerAnglesXYZ())
check(math.abs(total) < 0.15, "Agachado: la cabeza queda mirando al frente")

---------------------------------------------------------------------
print("\n▶ Agachado: entrar, salir, levantarse solo y reaparecer")
do
	local delayed = {}
	local fakeTask = {
		delay = function(_, fn)
			table.insert(delayed, fn)
		end,
		defer = function(fn)
			fn()
		end,
	}
	local function flush()
		local list = delayed
		delayed = {}
		for _, fn in list do
			fn()
		end
	end
	local state = Enum.HumanoidStateType.Running
	local jumpEnabled = true
	local humanoid = {
		Health = 100, HipHeight = 2, Sit = false, SeatPart = nil, PlatformStand = false, Jump = false,
		RigType = Enum.HumanoidRigType.R15,
		GetState = function()
			return state
		end,
		SetStateEnabled = function(_, kind, on)
			if kind == Enum.HumanoidStateType.Jumping then
				jumpEnabled = on
			end
		end,
	}
	local root = { Position = Vector3.new(0, 3, 0), Size = Vector3.new(2, 2, 1), CFrame = CFrame.new(0, 3, 0) }
	local character = {
		GetScale = function()
			return 1
		end,
		FindFirstChildOfClass = function(_, class)
			return if class == "Humanoid" then humanoid else nil
		end,
		FindFirstChild = function(_, name)
			return if name == "HumanoidRootPart" then root else nil
		end,
		WaitForChild = function()
			return humanoid
		end,
	}
	root.Parent = character
	local attrs = { LifeStage = "Adulto" }
	local fakePlayer = {
		Character = character,
		GetAttribute = function(_, k)
			return attrs[k]
		end,
		SetAttribute = function(_, k, v)
			attrs[k] = v
		end,
	}
	local sent = {}
	local fakeRemote = { FireServer = function(_, kind, value)
		table.insert(sent, kind .. ":" .. tostring(value))
	end }
	local ceiling = false
	local floorAt = function(_x: number, _z: number): number
		return 0
	end
	local env = {
		CFrame = CFrame, Vector3 = Vector3, Enum = Enum, script = {}, task = fakeTask,
		workspace = { CurrentCamera = {}, Raycast = function(_, from, dir)
			if dir.Y < -0.5 then -- el suelo: llano y a la misma altura en todas partes
				return { Position = Vector3.new(from.X, floorAt(from.X, from.Z), from.Z), Normal = Vector3.new(0, 1, 0), Material = Enum.Material.Grass }
			end
			return if ceiling and dir.Y > 0.5 then { Position = from + dir * 0.5 } else nil
		end },
		game = { GetService = function(_, name)
			return { Name = name, Shared = { Movement = "Movement" } }
		end },
		RaycastParams = { new = function()
			return {}
		end },
		require = function(what)
			assert(what == "Movement", "solo Movement")
			return Movement
		end,
	}
	local S = luau.load(fs.readFile("src/client/Controllers/Stances.luau"), { debugName = "Stances(estado)", environment = setmetatable(env, { __index = getfenv(1) }) })()
	S._attach(fakePlayer, fakeRemote)

	check(S.current() == "Stand" and S.speedFactor() == 1, "Empieza de pie, a velocidad normal")
	check(S.request("Crouch") and S.current() == "Crouch", "Agacharse")
	check(attrs.StanceLocal == "Crouch" and sent[#sent] == "Stance:Crouch", "Se avisa al servidor (y al botón) de que estás agachado")
	check(not jumpEnabled and math.abs(S.speedFactor() - Movement.Speed.Crouch) < 1e-9, "Agachado no salta (saltar te levanta) y va más despacio")
	S.toggleCrouch()
	check(S.current() == "Stand" and jumpEnabled and sent[#sent] == "Stance:Stand", "Otra vez: de pie, y se puede saltar")
	S.request("Crouch")
	ceiling = true
	check(not S.request("Stand", true) and S.current() == "Crouch", "Con un techo bajo encima no te levantas")
	ceiling = false
	humanoid.Jump = true
	S._watch() -- (acaba de agacharse: todavía no)
	check(S.current() == "Crouch", "Saltar justo al agacharte no te levanta aún")
	check(S.request("Stand") and S.request("Crouch"), "Agacharse de nuevo")
	state = Enum.HumanoidStateType.Climbing
	S._watch()
	check(S.current() == "Stand" and sent[#sent] == "Stance:Stand", "Al trepar una escalera te levantas solo")
	state = Enum.HumanoidStateType.Running
	check(not (function()
		state = Enum.HumanoidStateType.Swimming
		local ok = S.request("Crouch", true)
		state = Enum.HumanoidStateType.Running
		return ok
	end)(), "Nadando no te agachas")
	S.request("Crouch")
	humanoid.SeatPart = {}
	S._watch()
	check(S.current() == "Stand", "Al sentarte te levantas")
	humanoid.SeatPart = nil
	S.request("Crouch")
	attrs.Riding = "Patinete"
	S._watch()
	check(S.current() == "Stand", "Al montarte en algo te levantas")
	attrs.Riding = nil
	S.request("Crouch")
	humanoid.PlatformStand = true
	S._watch()
	check(S.current() == "Stand", "Caído (PlatformStand) te levantas")
	humanoid.PlatformStand = false
	-- Tumbarse y levantarse a mitad: "BusyMove" (arma bajada) no se queda puesto
	S.request("Prone")
	check(attrs.BusyMove == true, "Tumbándote, el arma se baja un momento")
	humanoid.SeatPart = {}
	S._watch() -- algo te levanta antes de acabar de tumbarte
	humanoid.SeatPart = nil
	flush()
	check(attrs.BusyMove == nil and S.current() == "Stand", "Y si algo te levanta a mitad, el arma no se queda bajada para siempre")
	-- El servidor corrige
	S.request("Crouch")
	S._fromServer("Stand", nil)
	check(S.current() == "Stand" and attrs.StanceLocal == "Stand" and jumpEnabled, "Si el servidor dice que no, vuelves a estar de pie (y se puede saltar)")
	local count = #sent
	S._fromServer("Volar", nil)
	check(S.current() == "Stand" and #sent == count, "Una postura rara del servidor se ignora")
	-- Reaparecer
	S.request("Prone")
	S._onCharacter(character)
	check(S.current() == "Stand" and attrs.StanceLocal == "Stand" and attrs.BusyMove == nil and jumpEnabled, "Al reaparecer: de pie, sin arma bajada y se puede saltar")
	flush()
	check(attrs.BusyMove == nil, "(y nada pendiente la vuelve a bajar)")
	-- Saltar para levantarse
	S.request("Crouch")
	S._watch()
	humanoid.Jump = true
	-- (pasa el tiempo)
	local clock = os.clock
	local t0 = clock()
	while clock() - t0 < 0.21 do
	end
	S._watch()
	check(S.current() == "Stand" and humanoid.Jump == false and not jumpEnabled, "Saltar agachado te levanta (sin saltar a la vez)")
	flush()
	check(jumpEnabled, "Y en cuanto estás de pie ya se puede saltar")
	-- Bebé
	attrs.LifeStage = "Bebe"
	check(not S.request("Crouch", true) and S.current() == "Stand", "Un bebé no se agacha")

	-----------------------------------------------------------------
	print("\n▶ Agachado en un cuerpo R15 (todas las piezas): pies en el suelo, sin patinar")
	-- Un R15 de mentira con las medidas de los motores (C0/C1) y la física justa: la raíz a HipHeight
	-- del suelo y moviéndose a su velocidad. Se mira dónde queda de verdad cada tobillo.
	for _, scale in { 1, 0.62 } do
		attrs.LifeStage = "Adulto"
		S._onCharacter(character)
		local function motor(c0: CFrame, c1: CFrame)
			return { C0 = c0, C1 = c1, Transform = CFrame.identity }
		end
		local k = scale
		local joints = {
			Root = motor(CFrame.new(0, -0.1 * k, 0), CFrame.new(0, 0.1 * k, 0)),
			Waist = motor(CFrame.new(0, 0.2 * k, 0), CFrame.new(0, -0.8 * k, 0)),
			Neck = motor(CFrame.new(0, 0.8 * k, 0), CFrame.new(0, -0.5 * k, 0)),
			RightShoulder = motor(CFrame.new(1 * k, 0.6 * k, 0), CFrame.new(0, 0.4 * k, 0)),
			LeftShoulder = motor(CFrame.new(-1 * k, 0.6 * k, 0), CFrame.new(0, 0.4 * k, 0)),
			RightElbow = motor(CFrame.new(0, -0.3 * k, 0), CFrame.new(0, 0.3 * k, 0)),
			LeftElbow = motor(CFrame.new(0, -0.3 * k, 0), CFrame.new(0, 0.3 * k, 0)),
			RightHip = motor(CFrame.new(0.5 * k, -0.2 * k, 0), CFrame.new(0, 0.6 * k, 0)),
			LeftHip = motor(CFrame.new(-0.5 * k, -0.2 * k, 0), CFrame.new(0, 0.6 * k, 0)),
			RightKnee = motor(CFrame.new(0, -0.6 * k, 0), CFrame.new(0, 0.5 * k, 0)),
			LeftKnee = motor(CFrame.new(0, -0.6 * k, 0), CFrame.new(0, 0.5 * k, 0)),
			RightAnkle = motor(CFrame.new(0, -0.5 * k, 0), CFrame.new(0, 0.05 * k, 0)),
			LeftAnkle = motor(CFrame.new(0, -0.5 * k, 0), CFrame.new(0, 0.05 * k, 0)),
		}
		-- (el pie: la suela 0,1 por debajo del tobillo)
		joints.RightAnkle.Part1 = { Size = Vector3.new(1 * k, 0.1 * k, 1.4 * k) }
		joints.LeftAnkle.Part1 = { Size = Vector3.new(1 * k, 0.1 * k, 1.4 * k) }
		local fakeLayers = {
			read = function(j)
				return j.Transform
			end,
			write = function(j, cf)
				j.Transform = cf
			end,
		}
		local fakeAge = { scaled = function(cf)
			return cf
		end }
		S._attach(fakePlayer, fakeRemote, fakeLayers, fakeAge)
		-- De pie, el tobillo queda justo a la altura de la suela: la raíz a HipHeight del suelo
		local rootHalf = 1 * k
		local restAnkleY = -0.1 * k - 0.1 * k - 0.2 * k - 0.6 * k - 0.6 * k - 0.5 * k - 0.5 * k -- (raíz → tobillo)
		local ankleAboveFloor = 0.1 * k
		humanoid.HipHeight = -restAnkleY + ankleAboveFloor - rootHalf
		local standHipHeight = humanoid.HipHeight
		local floorY = 0
		local speed = 0
		local pos = Vector3.new(0, floorY + rootHalf + humanoid.HipHeight, 0)
		root.Size = Vector3.new(2 * k, 2 * k, 1 * k)
		root.GetScale = nil
		character.GetScale = function()
			return k
		end
		local function place()
			pos = Vector3.new(pos.X, floorY + rootHalf + humanoid.HipHeight, pos.Z)
			root.Position = pos
			root.CFrame = CFrame.new(pos)
			root.AssemblyLinearVelocity = Vector3.new(0, 0, -speed)
		end
		place()
		local legs = {}
		for _, side in { 1, -1 } do
			local prefix = if side > 0 then "Right" else "Left"
			table.insert(legs, { Side = side, Hip = joints[prefix .. "Hip"], Knee = joints[prefix .. "Knee"], Ankle = joints[prefix .. "Ankle"], Ground = 0, Normal = Vector3.new(0, 1, 0) })
		end
		local model = character
		model.FindFirstChildOfClass = function(_, class)
			return if class == "Humanoid" then humanoid else nil
		end
		humanoid.FindFirstChildOfClass = function()
			return nil
		end
		local body = {
			Model = model, Humanoid = humanoid, Root = root, Player = fakePlayer, R6 = false, Joints = joints, Legs = legs,
			Crouch = 0, Prone = 0, Phase = 0, Step = 0, Move = 0, Speed = 0, Dir = Vector3.new(0, 0, -1), Seed = 0,
			LastPos = pos, Gesture = false, GestureAt = -1, Pitch = 0, Roll = 0, Lowest = nil, Scale = k,
		}
		local function ankleWorld(leg): (Vector3, CFrame)
			local r = joints.Root
			local chain = root.CFrame * r.C0 * r.Transform * r.C1:Inverse() * leg.Hip.C0 * leg.Hip.Transform * leg.Hip.C1:Inverse()
				* leg.Knee.C0 * leg.Knee.Transform * leg.Knee.C1:Inverse() * leg.Ankle.C0 * leg.Ankle.Transform
			return chain.Position, chain
		end
		local dt = 1 / 60
		local now = 0
		local function frame()
			for _, j in joints do
				j.Transform = CFrame.identity -- (la animación de este frame: de pie)
			end
			now += dt
			S._step(body, dt, now)
			pos += Vector3.new(0, 0, -speed * dt)
			place()
		end
		local tag = ("(tamaño %.2f)"):format(k)
		frame()
		local standY = ankleWorld(legs[1]).Y
		check(math.abs(standY - (floorY + ankleAboveFloor)) < 1e-4, "De pie, el tobillo está a su altura " .. tag)
		S.request("Crouch")
		local worstSink, worstFlat = 0, 0
		for _ = 1, 40 do
			frame()
			for _, leg in legs do
				local at, cf = ankleWorld(leg)
				worstSink = math.max(worstSink, math.abs(at.Y - standY))
				worstFlat = math.max(worstFlat, 1 - cf.UpVector.Y)
			end
		end
		local drop = standHipHeight - humanoid.HipHeight
		check(drop > 0.3 * (1.1 * 2) * k and drop < 0.4 * 2.2 * k, ("Agachado, el cuerpo baja de verdad (%.2f studs) %s"):format(drop, tag))
		check(worstSink < 0.01, ("Al agacharse y quieto, los pies ni se hunden ni flotan (%.4f) %s"):format(worstSink, tag))
		check(worstFlat < 1e-3, "Y los pies siguen planos " .. tag)
		local rk = select(1, joints.RightKnee.Transform:ToEulerAnglesXYZ())
		check(rk < -1.0, ("Las rodillas se doblan de verdad (%.2f rad) %s"):format(rk, tag))
		-- Andar agachado: el pie que apoya no se mueve del sitio
		speed = 16 * Movement.Speed.Crouch * k
		local planted: { [any]: Vector3 } = {}
		local slip, maxLift, cycles = 0, 0, 0
		local lastStep = body.Step
		for _ = 1, 240 do
			frame()
			if body.Step < lastStep then
				cycles += 1
			end
			lastStep = body.Step
			for _, leg in legs do
				local u = (body.Step + (if leg.Side > 0 then 0 else 0.5)) % 1
				local at = ankleWorld(leg)
				maxLift = math.max(maxLift, at.Y - standY)
				-- (en pleno apoyo, lejos de pisar y despegar, y ya a velocidad)
				if u > 0.08 and u < Stances.Gait.Duty - 0.08 and body.Move > 0.95 then
					if planted[leg] then
						slip = math.max(slip, Vector3.new(at.X - planted[leg].X, 0, at.Z - planted[leg].Z).Magnitude)
					end
					planted[leg] = planted[leg] or at
				else
					planted[leg] = nil
				end
			end
		end
		check(cycles >= 3, ("Andando agachado da pasos (%d ciclos en 4 s) %s"):format(cycles, tag))
		check(slip < 0.06 * k, ("El pie apoyado no patina (%.3f studs) %s"):format(slip, tag))
		check(maxLift > 0.05 * k and maxLift < 0.6 * k, ("El pie que da el paso se levanta un poco (%.2f) %s"):format(maxLift, tag))
		-- Parar y levantarse: vuelve justo a la altura de pie
		speed = 0
		S.request("Stand")
		for _ = 1, 60 do
			frame()
		end
		check(math.abs(humanoid.HipHeight - standHipHeight) < 1e-6, "Al levantarse, la altura vuelve exacta " .. tag)
		-- Un escalón bajo el pie derecho: ese pie se apoya encima (y el izquierdo sigue abajo)
		S.request("Crouch")
		floorAt = function(x: number, _z: number): number
			return if x > 0.3 * k then 0.3 * k else 0
		end
		for _ = 1, 60 do
			frame()
		end
		local right, left = ankleWorld(legs[1]), ankleWorld(legs[2])
		check(math.abs(right.Y - (standY + 0.3 * k)) < 0.01 and math.abs(left.Y - standY) < 0.01, ("Con un escalón bajo un pie, cada pie pisa su suelo (%.3f / %.3f) %s"):format(right.Y - standY, left.Y - standY, tag))
		floorAt = function()
			return 0
		end
		-- Otro jugador agachado: su HipHeight aquí es la de pie (no se replica) y su cuerpo baja por la
		-- red; las piernas cuadran con lo que se ve
		local other = { GetAttribute = function(_, key)
			return if key == "Stance" then "Crouch" else nil
		end }
		local lowered = standHipHeight - humanoid.HipHeight
		-- (su HipHeight aquí da igual: ni la de pie ni la agachada; se mide su suelo)
		humanoid.HipHeight = standHipHeight + 0.37
		body.Player = other
		local worstOther = 0
		for i = 1, 45 do
			for _, j in joints do
				j.Transform = CFrame.identity
			end
			now += dt
			-- (su posición llega algo tarde: a veces más alto, a veces más bajo de lo que dice su postura)
			local shown = lowered * (0.85 + 0.15 * math.sin(i))
			pos = Vector3.new(pos.X, floorY + rootHalf + standHipHeight - shown, pos.Z)
			root.Position = pos
			root.CFrame = CFrame.new(pos)
			root.AssemblyLinearVelocity = Vector3.zero
			S._step(body, dt, now)
			for _, leg in legs do
				if i > 15 then -- (el pie derecho acaba de bajar del escalón de antes: se posa con suavidad)
					worstOther = math.max(worstOther, math.abs(ankleWorld(leg).Y - standY))
				end
			end
		end
		check(worstOther < 0.01, ("Otro jugador agachado: sus pies en el suelo aunque su posición llegue a destiempo (%.4f) %s"):format(worstOther, tag))
		body.Player = fakePlayer
		S.request("Stand")
		for _ = 1, 60 do
			frame()
		end
		humanoid.HipHeight = 2
	end
end

---------------------------------------------------------------------
print("\n▶ Velocidades y reglas")
check(Movement.speedFactor("Stand") == 1 and Movement.speedFactor("Crouch") == 0.45 and Movement.speedFactor("Prone") == 0.25, "De pie 100 %, agachado 45 %, tumbado 25 %")
check(Movement.speedFactor(nil) == 1 and Movement.speedFactor("Volando") == 1, "Sin postura, como de pie")
check(Stances.blendSpeed(0, 0) == 1 and math.abs(Stances.blendSpeed(1, 0) - Movement.Speed.Crouch) < 1e-9 and Stances.blendSpeed(1, 1) == 0.25, "La velocidad sigue la postura")
local okBlend, prevSpeed = true, 2
for i = 0, 20 do
	local s = Stances.blendSpeed(i / 20, 0)
	okBlend = okBlend and s <= prevSpeed and s >= 0.25 and s <= 1
	prevSpeed = s
end
check(okBlend and math.abs(Stances.blendSpeed(5, -3) - Movement.Speed.Crouch) < 1e-9, "Y cambia suave, sin salirse (pesos fuera de 0..1 se recortan)")
check(Movement.witnessFactor("Crouch") == 0.5 and Movement.witnessFactor("Stand") == 1, "Agachado, los testigos tienen que estar a la mitad de distancia")
local normal = { Stage = "Adulto" }
check(Movement.allowed("Crouch", normal) and Movement.allowed("Prone", normal), "Un adulto a pie se agacha y se tumba")
check(Movement.allowed("Stand", { Riding = true, Dead = true }), "Ponerse de pie siempre vale")
check(not Movement.allowed("Crouch", { Stage = "Bebe" }), "Los bebés no (ya gatean)")
check(not Movement.allowed("Crouch", { Stage = "Adulto", Riding = true }), "Montado no")
check(not Movement.allowed("Prone", { Stage = "Adulto", Seated = true }), "Sentado no")
check(not Movement.allowed("Prone", { Stage = "Adulto", Swimming = true }), "Nadando no")
check(not Movement.allowed("Crouch", { Stage = "Adulto", Climbing = true }), "Trepando una escalera no")
check(not Movement.allowed("Crouch", { Stage = "Adulto", Ragdoll = true }) and not Movement.allowed("Crouch", { Stage = "Adulto", Busy = true }), "Caído o en una escena no")
check(not Movement.allowed("Volar", normal) and not Movement.allowed(nil, normal), "Una postura inventada no vale")

---------------------------------------------------------------------
print("\n▶ Posturas")
check(amount(Stances.crouchPose(0, 0, 0, 0, 0, 0)) < 1e-9, "Agachado con peso 0 no hace nada")
local hip, knee, ankle = Movement.crouchLegs(0.75, 1.2, 1.2)
local crouch = Stances.crouchPose(1, hip, knee, ankle, 1, 1.3)
check(poseFinite(crouch) and amount(crouch) > 0.3 and amount(crouch) < math.pi, "Agachado: valores normales y se nota")
local fineProne = true
for i = 0, 16 do
	local pose = Stances.pronePose(i % 2, i / 16 * math.pi * 2, 0.2, -0.1, -0.8)
	fineProne = fineProne and poseFinite(pose)
end
check(fineProne, "Tumbado (quieto y arrastrándose): valores normales")
local lying = Stances.pronePose(0, 0, 0, 0, 0)
check(math.abs(lying.Root.UpVector.Y) < 1e-6, "Tumbado: el cuerpo en horizontal")
check(lying.Root.UpVector.Z < -0.99, "Tumbado: la cabeza hacia delante")
local a = Stances.pronePose(1, math.pi / 2, 0, 0, 0)
local b = Stances.pronePose(1, -math.pi / 2, 0, 0, 0)
local ax = select(1, a.RightShoulder:ToEulerAnglesXYZ())
local bx = select(1, b.RightShoulder:ToEulerAnglesXYZ())
check(math.abs(ax - bx) > 0.3, "Arrastrándose, los brazos se alternan")
for kind, keys in Parkour.Keys do
	local sorted = keys[1].T == 0 and keys[#keys].T == 1
	for i = 2, #keys do
		sorted = sorted and keys[i].T > keys[i - 1].T
	end
	check(sorted, kind .. ": fotogramas en orden, de 0 a 1")
	check(amount(Parkour.pose(kind, 0)) < 1e-6 and amount(Parkour.pose(kind, 1)) < 1e-6, kind .. ": empieza y acaba en cero")
	local peak, fineAll = 0, true
	for i = 0, 50 do
		local pose = Parkour.pose(kind, i / 50)
		fineAll = fineAll and poseFinite(pose)
		peak = math.max(peak, amount(pose))
	end
	check(fineAll and peak > 0.5 and peak < math.pi, (kind .. ": valores normales y se mueve (%.2f rad)"):format(peak))
end
local okWeight = Parkour.weight(0, 0.6) == 0 and Parkour.weight(1, 0.6) == 0
for i = 0, 50 do
	local w = Parkour.weight(i / 50, 0.6)
	okWeight = okWeight and w >= 0 and w <= 1
end
check(okWeight and Parkour.weight(0.5, 0.6) == 1, "El peso del salto entra y sale (0 en los extremos, 1 en medio)")
local kind, start, duration = Parkour.parse("Kong|1234.500|0.60")
check(kind == "Kong" and start == 1234.5 and duration == 0.6, "El atributo Vault se lee bien")
check(Parkour.parse("Volar|1|1") == nil and Parkour.parse(nil) == nil and Parkour.parse("Kong|x|1") == nil, "Y uno raro se ignora")

---------------------------------------------------------------------
print("\n▶ Caer corriendo")
check(Locomotion.landing(120, 20) == "Roll", "Desde muy alto corriendo: voltereta")
check(Locomotion.landing(120, 2) == "Stumble", "Desde muy alto parado: traspiés")
check(Locomotion.landing(50, 20) == "Land", "Un salto normal corriendo: solo se agacha un poco")

print("")
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
